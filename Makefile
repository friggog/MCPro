ADDITIONAL_CFLAGS = -fobjc-arc

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MCPro
MCPro_FILES = Tweak.xm UIImage+ImageEffects.m CHQuickSwitcher.xm
MCPro_FRAMEWORKS = UIKit CoreGraphics QuartzCore Accelerate Security AddressBook
MCPro_PRIVATE_FRAMEWORKS = ChatKit
MCPro_LIBRARIES = MobileGestalt

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += mcproprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
