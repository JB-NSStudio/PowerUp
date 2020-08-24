include $(THEOS)/makefiles/common.mk
TARGET := iphone:clang:13.0:7.0
BUNDLE_NAME = powerupprefs

powerupprefs_FILES = $(wildcard *.m)
powerupprefs_INSTALL_PATH = /Library/PreferenceBundles
powerupprefs_FRAMEWORKS = UIKit
powerupprefs_EXTRA_FRAMEWORKS += Cephei CepheiPrefs
powerupprefs_PRIVATE_FRAMEWORKS = Preferences
powerupprefs_CFLAGS = -fobjc-arc 

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/powerupprefs.plist$(ECHO_END)
