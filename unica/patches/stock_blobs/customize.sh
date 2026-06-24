SOURCE_FIRMWARE_PATH="$FW_DIR/$(cut -d "/" -f 1 -s <<< "$SOURCE_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$SOURCE_FIRMWARE")"
TARGET_FIRMWARE_PATH="$FW_DIR/$(cut -d "/" -f 1 -s <<< "$TARGET_FIRMWARE")_$(cut -d "/" -f 2 -s <<< "$TARGET_FIRMWARE")"


LOG_STEP_IN "- Replacing saiv blobs with stock"
if [ -d "$TARGET_FIRMWARE_PATH/system/system/etc/saiv" ]; then
    BLOBS_LIST="
    system/etc/saiv/image_understanding/db/aic_classifier/aic_classifier_cnn.info
    system/etc/saiv/image_understanding/db/aic_detector/aic_detector_cnn.info
    "
    for blob in $BLOBS_LIST
    do
      if [ -f "$TARGET_FIRMWARE_PATH/system/$blob" ]; then
          ADD_TO_WORK_DIR "$TARGET_FIRMWARE_PATH" "system" "$blob" 0 0 644 "u:object_r:system_file:s0"
      fi
    done
else
    if [ -d "$WORK_DIR/system/system/etc/saiv" ]; then
        DELETE_FROM_WORK_DIR "system" "system/etc/saiv"
    fi
fi
DELETE_FROM_WORK_DIR "system" "system/saiv"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE_PATH" "system" "system/saiv" 0 0 755 "u:object_r:system_file:s0"
DELETE_FROM_WORK_DIR "system" "system/saiv/face"
ADD_TO_WORK_DIR "$SOURCE_FIRMWARE_PATH" "system" "system/saiv/face" 0 0 755 "u:object_r:system_file:s0"
DELETE_FROM_WORK_DIR "system" "system/saiv/textrecognition"
ADD_TO_WORK_DIR "$SOURCE_FIRMWARE_PATH" "system" "system/saiv/textrecognition" 0 0 755 "u:object_r:system_file:s0"
LOG_STEP_OUT

LOG_STEP_IN "- Replacing cameradata blobs with stock"
DELETE_FROM_WORK_DIR "system" "system/cameradata"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE_PATH" "system" "system/cameradata" 0 0 755 "u:object_r:system_file:s0"
DELETE_FROM_WORK_DIR "system" "system/cameradata/preloadfilters"
ADD_TO_WORK_DIR "$SOURCE_FIRMWARE_PATH" "system" "system/cameradata/preloadfilters" 0 0 755 "u:object_r:system_file:s0"
DELETE_FROM_WORK_DIR "system" "system/cameradata/myfilter"
ADD_TO_WORK_DIR "$SOURCE_FIRMWARE_PATH" "system" "system/cameradata/myfilter" 0 0 755 "u:object_r:system_file:s0"
LOG_STEP_OUT

if [ -f "$TARGET_FIRMWARE_PATH/system/system/usr/share/alsa/alsa.conf" ]; then
    LOG_STEP_IN "- Add stock alsa.conf"
    ADD_TO_WORK_DIR "$TARGET_FIRMWARE_PATH" "system" "system/usr/share/alsa/alsa.conf" 0 0 644 "u:object_r:system_file:s0"
    LOG_STEP_OUT
else
    if [ -d "$WORK_DIR/system/system/usr/share/alsa" ]; then
        DELETE_FROM_WORK_DIR "system" "system/usr/share/alsa"
    fi
fi

LOG_STEP_IN "- Replacing gamebooster props"
SET_PROP "product" "ro.gfx.driver.0" "$(GET_PROP "$WORK_DIR/vendor/build.prop" "ro.gfx.driver.0")"
SET_PROP "product" "ro.gfx.driver.1" "$(GET_PROP "$WORK_DIR/vendor/build.prop" "ro.gfx.driver.1")"
LOG_STEP_OUT
