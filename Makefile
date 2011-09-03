TWEAK_NAME = sandcastlev3
sandcastlev3_LOGOS_FILES = Tweak.xm
sandcastlev3_PRIVATE_FRAMEWORKS = AppSupport
sandcastlev3_CFLAGS=-I.

SUBPROJECTS = client

client_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries

include framework/makefiles/common.mk
include framework/makefiles/aggregate.mk
include framework/makefiles/tweak.mk
