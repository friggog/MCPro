ADDITIONAL_CFLAGS = -fobjc-arc

GO_EASY_ON_ME = 1

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = MCProPrefs
MCProPrefs_FILES = MCProPrefs.mm CircleViews.mm ColorPicker/HRBrightnessCursor.m ColorPicker/HRBrightnessSlider.m ColorPicker/HRColorCursor.m ColorPicker/HRColorInfoView.m ColorPicker/HRColorMapView.m ColorPicker/HRColorPickerView.m ColorPicker/HRHSVColorUtil.m ColorPicker/UIImage+CoreGraphics.m ColorPicker/HRAlphaSlider.m ColorPicker/HRAlphaCursor.m UIImage+ImageEffects.m
MCProPrefs_INSTALL_PATH = /Library/PreferenceBundles
MCProPrefs_FRAMEWORKS = UIKit QuartzCore CoreGraphics Social MessageUI AddressBook MobileCoreServices Accelerate
MCProPrefs_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/me.chewitt.mcpro.plist$(ECHO_END)
