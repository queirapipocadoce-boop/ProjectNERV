if [ "$TARGET_SINGLE_SYSTEM_IMAGE" == "self" ]; then
    return 0
fi

if [[ "$TARGET_CODENAME" == "a52sxq" ]] || [[ "$TARGET_FIRMWARE" == SM-A528B/* ]]; then
    # The S23 One UI 7 services.jar uses a different Package Manager layout;
    # the legacy signature-spoof patch expects absent smali_classes2 classes.
    # Keep services.jar stock on A52s because Package Manager is boot-critical.
    LOG "Skipping legacy platform-signature spoof for A52s (SM-A528B): incompatible services.jar layout"
    return 0
fi

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
