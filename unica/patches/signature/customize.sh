if [ "$TARGET_SINGLE_SYSTEM_IMAGE" == "self" ]; then
    return 0
fi

# This repository is A52s-only. The S23 One UI 7 services.jar uses a different
# Package Manager layout, and the legacy signature-spoof patch expects absent
# smali_classes2 classes. Keep services.jar stock because Package Manager is
# boot-critical; the optional signature-spoof feature is intentionally disabled.
LOG "Skipping legacy platform-signature spoof: A52s-only build keeps Package Manager stock"
return 0

CERT_PREFIX="aosp_platform"
$ROM_IS_OFFICIAL && CERT_PREFIX="platform"

CERT_SIGNATURE=$(cat "$SRC_DIR/security/${CERT_PREFIX}.x509.pem" | \
    sed '/CERTIFICATE/d' | tr -d '\n' | base64 -d | xxd -p -c 0)

FTP="
system/framework/services.jar/smali_classes2/com/android/server/pm/InstallPackageHelper.smali
"
for f in $FTP; do
    sed -i "s|PUT SIGNATURE HERE|$CERT_SIGNATURE|g" "$APKTOOL_DIR/$f"
done
