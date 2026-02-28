export THEOS_DEVICE_IP = 192.168.1.x
export THEOS_DEVICE_PORT = 22
ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ChromaHomeBarXPlus

ChromaHomeBarXPlus_FILES = ChromaHomeBarXPlus.xm
ChromaHomeBarXPlus_CFLAGS = -fobjc-arc
ChromaHomeBarXPlus_FRAMEWORKS = UIKit CoreGraphics QuartzCore AVFoundation
ChromaHomeBarXPlus_LIBRARIES = substrate
ChromaHomeBarXPlus_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = ChromaHomeBarXPlusPrefs

ChromaHomeBarXPlusPrefs_FILES = CHXPlusPrefsController.m
ChromaHomeBarXPlusPrefs_INSTALL_PATH = /Library/PreferenceBundles
ChromaHomeBarXPlusPrefs_FRAMEWORKS = UIKit Preferences
ChromaHomeBarXPlusPrefs_PRIVATE_FRAMEWORKS = Preferences
ChromaHomeBarXPlusPrefs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

after-install::
	install.exec "killall -9 SpringBoard"
