#!/usr/bin/env bash

# LCD AOD Compatibility Fix (A14 / Exynos 850)
#
# Three-component patch for always-on ("always show") AOD on LCD panels.
# Components [1]-[2] patch services.jar (already decoded upstream); component
# [3] decodes and patches AODService_v80.apk. This module supersedes the former
# separate aod_wander_compat module.
#
# Scope: this patch enables ALWAYS-SHOW AOD only. It deliberately makes NO doze
# changes for tap-to-show. Tap-to-show / single-tap-wake AOD is left disabled
# (the DOZE_SUSPEND remap and the TSP DisplayStateController remap that used to
# drive it have been removed) because that path bricks the A14 LCD on touch-wake.
#
#   [1] LocalDisplayAdapter — setDisplayState: DOZE(3)→MODE_NORMAL
#       The A14 vendor LCD HAL blanks the LCD on DOZE(3). We intercept and force
#       MODE_NORMAL(2) so the LCD stays on during active (always-show) AOD.
#       DOZE_SUSPEND(4) is left untouched — no tap-to-show standby handling.
#
#   [2] LightsService — setLightLocked: UnsupportedOperationException catch
#       A14's vendor lights HAL throws UnsupportedOperationException on DOZE
#       backlight calls. Without a catch this crashes PhotonicModulator, killing
#       DozeService and shutting AOD down. We add a silent catch block.
#
#   [3] AODService_v80 (DN.smali) — wandering range fix for LCD
#       On OLED the screen blanks during the lockscreen→AOD transition so the
#       burn-in protection wandering offset is invisible. With our forced
#       MODE_NORMAL fix [1] the LCD stays on, making the oversized wandering
#       offsets a visible slide animation. We force the small-range code paths
#       and zero PortNowBar (LCD has no burn-in risk). Targets a different
#       artifact (the APK, not services.jar), so it is decoded separately below.

# ── Component 1: LocalDisplayAdapter ────────────────────────────────────────

LOCAL_DISPLAY_DEVICE_SMALI=""
for dir in "$APKTOOL_DIR/system/framework/services.jar"/smali*; do
    if [ -f "$dir/com/android/server/display/LocalDisplayAdapter\$LocalDisplayDevice\$1.smali" ]; then
        LOCAL_DISPLAY_DEVICE_SMALI="$dir/com/android/server/display/LocalDisplayAdapter\$LocalDisplayDevice\$1.smali"
        break
    fi
done

if [ -f "$LOCAL_DISPLAY_DEVICE_SMALI" ]; then
    LOG "- [lcd_aod_fix/1] Patching LocalDisplayAdapter setDisplayState for LCD AOD"
    python3 -c '
import re
import sys

file_path = sys.argv[1]
with open(file_path, "r") as f:
    content = f.read()

method_m = re.search(
    r"\.method (?:(?:public|private|protected|static|final|synthetic)\s+)*setDisplayState\(I\)V",
    content
)
if not method_m:
    print("Warning: setDisplayState method not found — skipping component 1")
    sys.exit(0)

end_m = re.search(r"\.end method", content[method_m.end():])
if not end_m:
    print("Warning: .end method not found — skipping component 1")
    sys.exit(0)

method_start = method_m.start()
method_end_abs = method_m.end() + end_m.end()
method_body = content[method_start:method_end_abs]

regs_m = re.search(r"\.registers\s+(\d+)", method_body)
if not regs_m:
    regs_m = re.search(r"\.locals\s+(\d+)", method_body)
has_v2 = bool(regs_m and int(regs_m.group(1)) >= 3)

copy_m = re.search(r"(    move/from16 v1, p1\n)", method_body) or \
         re.search(r"(    move v1, p1\n)", method_body)

# ── DOZE(3) → MODE_NORMAL ───────────────────────────────────────────────────
# Primary: remove the if-eqz for the DOZE(3) branch only.
# DOZE_SUSPEND(4) has an identical guarded block appearing first; we remove
# only the 2nd match (DOZE). After removal the DOZE path falls through to the
# code that already sends MODE_NORMAL for the charging-UI case.
doze_fixed = False

aod_flag_pattern = (
    r"(    sget-boolean v\d+, Lcom/android/server/power/PowerManagerUtil;"
    r"->SEC_FEATURE_AOD_LOOK_CHARGING_UI:Z\n)"
    r"\n?"
    r"    if-eqz v\d+, :\w+\n"
    r"\n?"
    r"(    goto :\w+\n)"
)
matches = list(re.finditer(aod_flag_pattern, method_body))

if ":aod_tap_cont" in method_body:
    doze_fixed = True  # fallback was applied in a prior build
elif len(matches) >= 2:
    m = matches[1]
    method_body = method_body[:m.start()] + m.group(1) + m.group(2) + method_body[m.end():]
    doze_fixed = True
    print("OK: removed SEC_FEATURE_AOD_LOOK_CHARGING_UI if-eqz for DOZE(3)")
elif "SEC_FEATURE_AOD_LOOK_CHARGING_UI" in method_body:
    doze_fixed = True  # primary already applied (1 match left: the untouched DOZE_SUSPEND block)

# Fallback for DOZE(3) when the AOD flag pattern is absent
if not doze_fixed:
    print(f"Note: primary pattern not found ({len(matches)} matches) — trying injection fallback")
    if not has_v2:
        print("Warning: insufficient registers — DOZE(3) fix not applied")
    elif not copy_m:
        print("Warning: move v1, p1 not found — DOZE(3) fix not applied")
    else:
        doze_inj = (
            "    const/4 v2, 0x3\n"
            "    if-ne v1, v2, :aod_tap_cont\n"
            "    const/4 v1, 0x2\n"
            "\n"
            "    :aod_tap_cont\n"
        )
        method_body = method_body[:copy_m.end()] + doze_inj + method_body[copy_m.end():]
        doze_fixed = True
        print("OK: fallback injection — DOZE(3)→MODE_NORMAL")

# DOZE_SUSPEND(4) is intentionally left untouched: this patch enables always-show
# AOD only and makes no tap-to-show standby changes. The original DOZE_SUSPEND
# guarded block stays intact so the framework keeps its default behaviour.

new_content = content[:method_start] + method_body + content[method_end_abs:]
with open(file_path, "w") as f:
    f.write(new_content)
' "$LOCAL_DISPLAY_DEVICE_SMALI"
else
    LOGW "LocalDisplayAdapter\$LocalDisplayDevice\$1.smali not found — skipping component 1"
fi

# ── Component 2: LightsService ───────────────────────────────────────────────

LIGHTS_SMALI=""
for dir in "$APKTOOL_DIR/system/framework/services.jar"/smali*; do
    if [ -f "$dir/com/android/server/lights/LightsService\$LightImpl.smali" ]; then
        LIGHTS_SMALI="$dir/com/android/server/lights/LightsService\$LightImpl.smali"
        break
    fi
done

if [ -f "$LIGHTS_SMALI" ]; then
    LOG "- [lcd_aod_fix/2] Patching LightsService UnsupportedOperationException catch"
    python3 -c '
import re
import sys

file_path = sys.argv[1]
with open(file_path, "r") as f:
    content = f.read()

if "catch_unsupported_lights" in content:
    print("Already patched — skipping component 2")
    sys.exit(0)

pattern = r"(\.catch Landroid/os/RemoteException; \{:try_start_\w+ \.\. :try_end_\w+\} :\w+)"

def inject_catch(m):
    original = m.group(1)
    range_match = re.search(r"(\{:try_start_\w+ \.\. :try_end_\w+\})", original)
    if not range_match:
        return original
    return (
        f"{original}\n"
        f"    .catch Ljava/lang/UnsupportedOperationException; "
        f"{range_match.group(1)} :catch_unsupported_lights"
    )

method_pattern = r"(\.method (?:(?:public|private|protected|static|final|synthetic)\s+)*setLightLocked\(.*?\)V.*?\.end method)"
def patch_method(mm):
    body = mm.group(1)
    if "catch_unsupported_lights" in body:
        return body
    patched, count = re.subn(pattern, inject_catch, body)
    if count > 0:
        patched = patched.replace(
            ".end method",
            "    :catch_unsupported_lights\n"
            "    move-exception v0\n"
            "    return-void\n"
            ".end method"
        )
    return patched

new_content, cnt = re.subn(method_pattern, patch_method, content, flags=re.DOTALL)
if cnt > 0 and "catch_unsupported_lights" in new_content:
    with open(file_path, "w") as f:
        f.write(new_content)
    print("OK: UnsupportedOperationException catch added to setLightLocked")
else:
    print("Warning: setLightLocked pattern not found — component 2 not applied")
' "$LIGHTS_SMALI"
else
    LOGW "LightsService\$LightImpl.smali not found — skipping component 3"
fi

# ── Component 3: AODService_v80 wandering ranges ─────────────────────────────
#
# SEC_FLOATING_FEATURE_LCD_CONFIG_AOD_FULLSCREEN is 0 on A14 (not present in the
# feature XML), so R51.V() returns false, selecting oversized wandering Rects in
# DN.smali:
#   PortClock:      Rect(-68, 0, 68, 712)         → visible 712px vertical slide
#   PortBattery:    Rect(-96, -16, 40, 120)        → visible slide
#   PortPinButton:  Rect(-60, -40, 60, 80)         → visible slide
#   PortBottom:     device-type specific ranges    → visible slide
#   LandBattery:    Rect(-252, 0, 0, 40)           → visible slide
#   LandNIO:        Rect(0, 0, 320, 40)            → visible 320px horizontal slide
#   ExtraClock:     Rect(-484, -60, 484, 0)        → visible 968px horizontal slide (non-fold path)
#   PortNowBar:     Rect(-140, -60, 140, 60)       → always large (no R51.V() check)
#   PortNIO:        Rect(-44, -16, 180, 120)       → visible slide
#
# Fix: force the R51.V()=true (small-range) code paths by removing the if-eqz branch.
# Zero out PortNowBar's range since LCD panels have no OLED burn-in risk.
#
# Matching strategy: label names (cond_NNN) differ between APK versions, so we match
# each if-eqz by the true-path content that immediately follows it (first instruction
# or constant load that is unique to that branch).
# LandNIO and PortNIO share the same true-path register pattern {v0,v1,v1,v14,v13};
# they are patched with two sequential calls — LandNIO appears first in the file so
# the first call removes LandNIO if-eqz, the second removes PortNIO.

DECODE_APK "system" "system/priv-app/AODService_v80/AODService_v80.apk"

AOD_APK_DIR=""
for dir in "$APKTOOL_DIR/system/priv-app/AODService_v80/AODService_v80.apk"/smali*; do
    if [ -f "$dir/aod/DN.smali" ]; then
        AOD_APK_DIR="$dir"
        break
    fi
done

if [ -n "$AOD_APK_DIR" ]; then
    DN_SMALI="$AOD_APK_DIR/aod/DN.smali"
    LOG "- [lcd_aod_fix/3] Patching AOD wandering ranges for LCD at: $DN_SMALI"
    python3 -c '
import re
import sys

file_path = sys.argv[1]
with open(file_path, "r") as f:
    content = f.read()

original = content
patches_applied = 0


def remove_if_eqz_before(content, true_path_anchor):
    """Remove the if-eqz v0, :cond_X line that immediately precedes true_path_anchor."""
    pattern = r"\n    if-eqz v0, :cond_\w+\n(" + re.escape(true_path_anchor) + ")"
    m = re.search(pattern, content)
    if m:
        replaced = content[:m.start()] + "\n" + m.group(1) + content[m.end():]
        return replaced, True
    return content, False


# PortClock: true-path Rect(-32, 0, 32, 120) — false-path Rect(-68, 0, 68, 712)
# Identified by const/16 v2, 0x78 immediately after new-instance
content, ok = remove_if_eqz_before(
    content,
    "\n    new-instance v0, Landroid/graphics/Rect;\n\n    const/16 v2, 0x78\n"
)
if ok:
    patches_applied += 1
    print("PortClock: removed if-eqz — uses Rect(-32, 0, 32, 120) instead of Rect(-68, 0, 68, 712)")
else:
    print("Warning: PortClock pattern not found — already patched or APK changed")

# PortBattery: true-path Rect(-88, 0, 0, 8) — false-path Rect(-96, -16, 40, 120)
# Identified by const/16 v2, -0x58 immediately after new-instance
content, ok = remove_if_eqz_before(
    content,
    "\n    new-instance v0, Landroid/graphics/Rect;\n\n    const/16 v2, -0x58\n"
)
if ok:
    patches_applied += 1
    print("PortBattery: removed if-eqz — uses Rect(-88, 0, 0, 8) instead of Rect(-96, -16, 40, 120)")
else:
    print("Warning: PortBattery pattern not found — already patched or APK changed")

# PortPinButton: true-path Rect(-40, 0, 40, 8) via {v0, v2, v1, v15, v13}
# false-path Rect(-60, -40, 60, 80)
content, ok = remove_if_eqz_before(
    content,
    "\n    new-instance v0, Landroid/graphics/Rect;\n\n    invoke-direct {v0, v2, v1, v15, v13}, Landroid/graphics/Rect;-><init>(IIII)V\n"
)
if ok:
    patches_applied += 1
    print("PortPinButton: removed if-eqz — uses Rect(-40, 0, 40, 8) instead of Rect(-60, -40, 60, 80)")
else:
    print("PortPinButton: already patched or APK changed — skipping")

# PortBottom: true-path Rect(-30, -52, 30, 0) — identified by const/16 v2, 0x1e after new-instance
# false-path: device-type specific ranges (much larger)
content, ok = remove_if_eqz_before(
    content,
    "\n    new-instance v0, Landroid/graphics/Rect;\n\n    const/16 v2, 0x1e\n"
)
if ok:
    patches_applied += 1
    print("PortBottom: removed if-eqz — uses Rect(-30, -52, 30, 0) instead of device-specific large range")
else:
    print("Warning: PortBottom pattern not found — already patched or APK changed")

# ExtraClock: true-path Rect(-60, -32, 60, 32) via {v0, v12, v6, v11, v7}
# false-path on non-fold A14: Rect(-484, -60, 484, 0) — 968px horizontal range
content, ok = remove_if_eqz_before(
    content,
    "\n    new-instance v0, Landroid/graphics/Rect;\n\n    invoke-direct {v0, v12, v6, v11, v7}, Landroid/graphics/Rect;-><init>(IIII)V\n"
)
if ok:
    patches_applied += 1
    print("ExtraClock: removed if-eqz — uses Rect(-60, -32, 60, 32) instead of Rect(-484, -60, 484, 0)")
else:
    print("ExtraClock: already patched or APK changed — skipping")

# LandBattery: true-path Rect(-80, 0, 0, 8) via {v0, v8, v1, v1, v13}
# false-path Rect(-252, 0, 0, 40)
content, ok = remove_if_eqz_before(
    content,
    "\n    new-instance v0, Landroid/graphics/Rect;\n\n    invoke-direct {v0, v8, v1, v1, v13}, Landroid/graphics/Rect;-><init>(IIII)V\n"
)
if ok:
    patches_applied += 1
    print("LandBattery: removed if-eqz — uses Rect(-80, 0, 0, 8) instead of Rect(-252, 0, 0, 40)")
else:
    print("Warning: LandBattery pattern not found — already patched or APK changed")

# LandNIO: true-path Rect(0, 0, 80, 8) via {v0, v1, v1, v14, v13} — first match in file
# false-path Rect(0, 0, 320, 40)
# Note: PortNIO shares the same register pattern; LandNIO appears earlier in the file so
# this first call removes the LandNIO if-eqz, leaving the PortNIO one for the next call.
content, ok = remove_if_eqz_before(
    content,
    "\n    new-instance v0, Landroid/graphics/Rect;\n\n    invoke-direct {v0, v1, v1, v14, v13}, Landroid/graphics/Rect;-><init>(IIII)V\n"
)
if ok:
    patches_applied += 1
    print("LandNIO: removed if-eqz — uses Rect(0, 0, 80, 8) instead of Rect(0, 0, 320, 40)")
else:
    print("Warning: LandNIO pattern not found — already patched or APK changed")

# PortNIO: true-path Rect(0, 0, 80, 8) via {v0, v1, v1, v14, v13} — second match in file
# false-path Rect(-44, -16, 180, 120)
content, ok = remove_if_eqz_before(
    content,
    "\n    new-instance v0, Landroid/graphics/Rect;\n\n    invoke-direct {v0, v1, v1, v14, v13}, Landroid/graphics/Rect;-><init>(IIII)V\n"
)
if ok:
    patches_applied += 1
    print("PortNIO: removed if-eqz — uses Rect(0, 0, 80, 8) instead of Rect(-44, -16, 180, 120)")
else:
    print("Warning: PortNIO pattern not found — already patched or APK changed")

# PortNowBar: zero out Rect(-140, -60, 140, 60) — LCD has no OLED burn-in risk
nowbar_invoke = "    invoke-direct {v0, v3, v12, v4, v11}, Landroid/graphics/Rect;-><init>(IIII)V"
nowbar_replacement = (
    "    const/4 v3, 0x0\n\n"
    "    const/4 v12, 0x0\n\n"
    "    const/4 v4, 0x0\n\n"
    "    const/4 v11, 0x0\n\n"
    "    invoke-direct {v0, v3, v12, v4, v11}, Landroid/graphics/Rect;-><init>(IIII)V"
)
if nowbar_invoke in content and "const/4 v3, 0x0" not in content:
    content = content.replace(nowbar_invoke, nowbar_replacement, 1)
    patches_applied += 1
    print("PortNowBar: zeroed wandering range Rect(-140, -60, 140, 60) -> Rect(0, 0, 0, 0)")
elif "const/4 v3, 0x0" in content:
    print("PortNowBar: already zeroed — skipping")
else:
    print("Warning: PortNowBar invoke-direct not found — already patched or APK changed")

if patches_applied > 0:
    with open(file_path, "w") as f:
        f.write(content)
    print(f"Successfully applied {patches_applied}/9 AOD wandering range patches to DN.smali")
elif content == original:
    print("No changes made to DN.smali")
' "$DN_SMALI"
else
    LOGW "AODService_v80 DN.smali not found in decoded APK — skipping component 3"
fi

LOG "-Enable AOD always-on doze mode"
SET_PROP "system" "ro.doze.always_on" "true"

Log "-Setting Floating Feature configs for AOD"
SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_FRAMEWORK_CONFIG_AOD_ITEM" "aodversion=7,clocktransition,aod_lcd_panel"
SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_LCD_SUPPORT_AOD" "TRUE"
SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_LCD_SUPPORT_DOZE_AP_SLEEP" "TRUE"
SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_LCD_CONFIG_AOD_BRIGHTNESS_ANIMATION" "0"
SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_LCD_CONFIG_AOD_FULLSCREEN" "0"