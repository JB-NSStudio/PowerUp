# THEOS_DEVICE_IP = localhost
# THEOS_DEVICE_PORT = 2222
FOR_RELEASE= 1
export ARCHS = arm64 arm64e
export TARGET := iphone:clang:11.2
export INSTALL_TARGET_PROCESSES = thermalmonitord backboardd SpringBoard 



include $(THEOS)/makefiles/common.mk

# GO_EASY_ON_ME = 1

TWEAK_NAME = PowerUp

${TWEAK_NAME}_FRAMEWORKS = Foundation IOKit MobileCoreServices
${TWEAK_NAME}_EXTRA_FRAMEWORKS += Cephei
${TWEAK_NAME}_CFLAGS = -fobjc-arc 
${TWEAK_NAME}_FILES = Tweak.xm ux.m

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += powerupprefs rootmepls
include $(THEOS_MAKE_PATH)/aggregate.mk

before-stage::
	cp .theos/obj/debug/PowerUp_RootMePls "./layout/Library/Application Support/PowerUp.bundle/";
	chmod 6755 "./layout/Library/Application Support/PowerUp.bundle/PowerUp_RootMePls";