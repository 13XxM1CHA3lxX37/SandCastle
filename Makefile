TWEAK_NAME = sandstone
sandstone_LOGOS_FILES = Tweak.xm
sandstone_PRIVATE_FRAMEWORKS = AppSupport
sandstone_CFLAGS=-I.

SUBPROJECTS = client

client_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries

include framework/makefiles/common.mk
include framework/makefiles/aggregate.mk
include framework/makefiles/tweak.mk
