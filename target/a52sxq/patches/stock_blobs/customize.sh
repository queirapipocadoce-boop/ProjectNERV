# A52s-only stock blob policy.
# Keep device-specific binaries from the target firmware and do not import
# legacy A73/PA1 prebuilts into the A52s system or vendor partitions.

LOG_STEP_IN "- Adding A52s stock feature permissions"
DELETE_FROM_WORK_DIR "system" "system/etc/permissions/com.sec.feature.cover.clearcameraviewcover.xml"
DELETE_FROM_WORK_DIR "system" "system/etc/permissions/com.sec.feature.cover.flip.xml"
DELETE_FROM_WORK_DIR "system" "system/etc/permissions/com.sec.feature.pocketsensitivitymode_level1.xml"
DELETE_FROM_WORK_DIR "system" "system/etc/permissions/com.sec.feature.sensorhub_level29.xml"
DELETE_FROM_WORK_DIR "system" "system/etc/permissions/com.sec.feature.wirelesscharger_authentication.xml"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/com.sec.feature.cover.minisviewwalletcover.xml" 0 0 644 "u:object_r:system_file:s0"
ADD_TO_WORK_DIR "$TARGET_FIRMWARE" "system" "system/etc/permissions/com.sec.feature.sensorhub_level40.xml" 0 0 644 "u:object_r:system_file:s0"
LOG_STEP_OUT

# The previous script imported A73/PA1 keymaster, camera, SAIV, NFC, WFD,
# wpa_supplicant, light HAL, libhwui and Google Assistant blobs. Those blobs
# are not A52s components and may cause ABI, hardware-service, or boot issues.
# The A52s build intentionally keeps the source/target-compatible stock blobs
# and does not import foreign device prebuilts.
LOG "Skipping legacy A73/PA1 stock-blob replacements for A52s"

return 0
