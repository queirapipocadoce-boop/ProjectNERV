LOG "Remove AODService & replace it with stock ClockPack"
DELETE_FROM_WORK_DIR "system" "system/priv-app/AODService_v80"
DELETE_FROM_WORK_DIR "system" "system/etc/permissions/com.samsung.feature.aodservice_v10.xml"
DELETE_FROM_WORK_DIR "system" "system/etc/permissions/privapp-permissions-com.samsung.android.app.aodservice.xml"

ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/priv-app/ClockPack_v80" 0 0 755 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/com.samsung.feature.clockpack_v10.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/privapp-permissions-com.samsung.android.app.clockpack.xml" 0 0 644 "u:object_r:system_file:s0"

LOG "-Fixing SELinux contexts for ClockPack"
echo "/system/priv-app/ClockPack_v80/ClockPack_v80\\.apk u:object_r:system_file:s0" >> "$WORK_DIR/configs/file_context-system"

LOG "-Setting Floating Feature configs for ClockPack"
SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_LCD_CONFIG_AOD_BRIGHTNESS_ANIMATION" "-d"
SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_LCD_CONFIG_AOD_FULLSCREEN" "-d"
SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_FRAMEWORK_CONFIG_AOD_ITEM" "-d"
SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_LCD_CONFIG_AOD_REFRESH_RATE" "-d"
SET_FLOATING_FEATURE_CONFIG "SEC_FLOATING_FEATURE_FRAMEWORK_CONFIG_CLOCKPACK_ITEM" "clockpackversion=7"