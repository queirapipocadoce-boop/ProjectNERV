#
# Copyright (C) 2025 BasGame1
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

# Debloat list for the Exynos 850 platform, using Exynos 990 platform files
# - Add entries inside the specific partition containing that file (<PARTITION>_DEBLOAT+="")
# - DO NOT add the partition name at the start of any entry (eg. "/system/dpolicy_system")
# - DO NOT add a slash at the start of any entry (eg. "/dpolicy_system")

# Camera SDK
SYSTEM_DEBLOAT+="
system/etc/default-permissions/default-permissions-com.samsung.android.globalpostprocmgr.xml
system/etc/default-permissions/default-permissions-com.samsung.petservice.xml
system/etc/default-permissions/default-permissions-com.samsung.videoscan.xml
system/etc/default-permissions/default-permissions-com.sec.factory.cameralyzer.xml
system/etc/permissions/cameraservice.xml
system/etc/permissions/privapp-permissions-com.samsung.android.globalpostprocmgr.xml
system/etc/permissions/privapp-permissions-com.samsung.petservice.xml
system/etc/permissions/privapp-permissions-com.samsung.videoscan.xml
system/etc/permissions/sec_camerax_impl.xml
system/etc/permissions/sec_camerax_service.xml
system/framework/sec_camerax_impl.jar
system/framework/scamera_sep.jar
system/priv-app/GlobalPostProcMgr
system/priv-app/PetService
system/priv-app/SCameraSDKService
system/priv-app/sec_camerax_service
system/priv-app/VideoScan
system/etc/permissions/privapp-permissions-com.samsung.ipservice.xml
system/priv-app/IPService
system/priv-app/DeviceQualityAgent35
system/priv-app/SMT
system/priv-app/SamsungSmartSuggestions
system/priv-app/MediaSearch
system/app/BixbyRoutines
system/priv-app/BixbyRoutines
system/priv-app/McfServer
system/priv-app/Mcfds
system/priv-app/BeaconManager
system/priv-app/SecSdhms
system/priv-app/KnoxCore
system/app/KnoxAttestationAgent
system/priv-app/KLMSAgent
system/app/UniversalMDMClient
system/app/TEEgrisTuiService
system/bin/insthk
system/etc/init/insthk_teegris.rc
system/etc/sysconfig/preinstalled-packages-com.samsung.sec.android.teegris.tui_service.xml
system/priv-app/CMHProvider
system/priv-app/USBSettings
system/etc/permissions/privapp-permissions-com.sec.usbsettings.xml
system/priv-app/RubinVersion36
system/etc/default-permissions/default-permissions-com.samsung.android.rubin.app.xml
system/etc/permissions/privapp-permissions-com.samsung.android.rubin.app.xml
system/etc/permissions/signature-permissions-com.samsung.android.rubin.app.xml
system/priv-app/Fmm
system/etc/permissions/privapp-permissions-com.samsung.android.fmm.xml
system/priv-app/SohService
system/priv-app/MFContents
system/etc/permissions/privapp-permissions-com.samsung.mfcontents.xml
system/etc/default-permissions/default-permissions-com.samsung.mfcontents.xml
system/app/WifiAiService
system/priv-app/SVCAgent
system/etc/permissions/privapp-permissions-com.samsung.android.svcagent.xml
system/app/DAAgent
system/priv-app/AREmoji
system/etc/permissions/privapp-permissions-com.samsung.android.aremoji.xml
system/etc/permissions/com.samsung.feature.aremoji_v2.xml
system/etc/default-permissions/default-permissions-com.samsung.android.aremoji.xml
system/priv-app/AREmojiEditor
system/etc/permissions/privapp-permissions-com.samsung.android.aremojieditor.xml
system/priv-app/AvatarEmojiSticker
system/priv-app/AvatarPicker
system/priv-app/StickerFaceARAvatar
system/priv-app/AutoDoodle
system/etc/permissions/privapp-permissions-com.sec.android.mimage.autodoodle.service.xml
system/etc/default-permissions/default-permissions-com.samsung.android.hwresourceshare.storage.xml
system/etc/init/ksmbd.rc
system/etc/permissions/privapp-permissions-com.samsung.android.hwresourceshare.storage.xml
system/etc/sysconfig/preinstalled-packages-com.samsung.android.hwresourceshare.storage.xml
system/etc/ksmbd.conf
system/priv-app/StorageShare
system/priv-app/AppUpdateCenter
system/priv-app/BadgeProvider_N
system/priv-app/BixbyInterpreter
system/priv-app/BixbyVisionFramework3.5
system/priv-app/EarphoneTypeC
system/priv-app/EnhancedAttestationAgent
system/priv-app/FacAtFunction
system/priv-app/Firewall
system/priv-app/HashTagService
system/priv-app/ImsLogger
system/priv-app/IntelligentDynamicFpsService
system/priv-app/IpsGeofence
system/priv-app/LinkToWindowsService
system/priv-app/ModemServiceMode
system/priv-app/OdaService
system/priv-app/SamsungBilling
system/priv-app/SamsungCalendarProvider
system/priv-app/SamsungIntelliVoiceServices
system/priv-app/SamsungMagnifier3
system/priv-app/SamsungPositioning
system/priv-app/SmartSwitchAssistant
system/priv-app/SPPPushClient
system/priv-app/Tag
system/priv-app/TalkbackSE
system/priv-app/VexScanner
system/app/ARCore
system/app/BBCAgent
system/app/BookmarkProvider
system/app/ChromeCustomizations
system/app/FactoryAirCommandManager
system/app/FactoryCameraFB
system/app/Fast
system/app/GearManagerStub
system/app/HMT
system/app/LiveTranscribe
system/app/MAPSAgent
system/app/MDMApp
system/app/MoccaMobile
system/app/ParentalCare
system/app/PartnerbookmarksProvider
system/app/Rampart
system/app/SamsungTTS
system/app/SamsungTTSVoice_el_GR_f00
system/app/SketchBook
system/app/SmartSwitchAgent
system/app/SmartSwitchStub
system/app/SticketCenter
system/app/UnificedWFC
system/app/VideoEditorLite_Dream_N
system/app/VideoTrimmer
system/app/VisionIntelligence3.7
system/app/WifiGuider
system/app/WifiRROverlayAppH2E
system/app/WifiRROverlayAppQC
system/app/WifiRROverlayAppWifiLock
"

PRODUCT_DEBLOAT+="
overlay/SoftapOverlayDualAp
overlay/SoftapOverlayOWE
app/com.google.mainline.adservices
app/com.google.mainline.telemetry
app/GoogleCalendarSyncAdapter
app/GoogleLocationHistory
app/SpeechServicesByGoogle
priv-app/AiWallpaper
priv-app/GooglePartnerSetup
"