#!/usr/bin/env bash

# Hide AOD menu from Settings (A14)
#
# LockUtils.isSupportAodService() checks whether
# SEC_FLOATING_FEATURE_FRAMEWORK_CONFIG_AOD_ITEM contains "aodversion".
# We force it to always return false so the AOD section never appears in
# the Settings UI, regardless of what floating features are set.

DECODE_APK "system" "system/priv-app/SecSettings/SecSettings.apk"

LOCKUTILS_SMALI=""
for dir in "$APKTOOL_DIR/system/priv-app/SecSettings/SecSettings.apk"/smali*; do
    if [ -f "$dir/com/samsung/android/settings/lockscreen/LockUtils.smali" ]; then
        LOCKUTILS_SMALI="$dir/com/samsung/android/settings/lockscreen/LockUtils.smali"
        break
    fi
done

if [ -f "$LOCKUTILS_SMALI" ]; then
    LOG "- [aod_menu_hide] Patching LockUtils.isSupportAodService() to return false"
    python3 -c '
import re
import sys

file_path = sys.argv[1]
with open(file_path, "r") as f:
    content = f.read()

if "aod_menu_hide_applied" in content:
    print("Already patched — skipping")
    sys.exit(0)

m = re.search(
    r"(\.method public static isSupportAodService\(\)Z\n)"
    r"(.+?)"
    r"(\.end method)",
    content, re.DOTALL
)
if not m:
    print("ERROR: isSupportAodService() not found in LockUtils.smali")
    sys.exit(1)

new_body = (
    "    .locals 1\n"
    "\n"
    "    # aod_menu_hide_applied\n"
    "    const/4 v0, 0x0\n"
    "\n"
    "    return v0\n"
)
new_content = content[:m.start(2)] + new_body + content[m.start(3):]

with open(file_path, "w") as f:
    f.write(new_content)

print("OK: isSupportAodService() forced to return false — AOD menu hidden")
' "$LOCKUTILS_SMALI" || { LOGE "[aod_menu_hide] Patch failed"; return 1; }
else
    LOGE "LockUtils.smali not found in SecSettings — skipping aod_menu_hide"
    return 1
fi
