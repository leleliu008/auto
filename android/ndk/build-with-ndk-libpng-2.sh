#/bin/sh

#################################################################
#注意：请将此脚本放置于源码根目录下
#参考：http://blog.fpliu.com/it/software/libpng/build-for-android-with-ndk-build
#################################################################

Color_Green='\033[0;32m'        # Green
Color_Off='\033[0m'             # Reset

msg() {
    printf "%b" "$1"
}

success() {
    msg "${Color_Green}[✔] $@${Color_Off}"
}

build() {
    cat > Android.mk <<EOF
LOCAL_PATH      := \$(call my-dir)

include \$(CLEAR_VARS)

LOCAL_MODULE    := png
LOCAL_SRC_FILES := \$(shell ls png*.c arm/*.c arm/*.S | awk '{gsub("pnglibconf.c","");print}')
LOCAL_LDLIBS    += -lz
LOCAL_CFLAGS    += -Os -v -DHAVE_CONFIG_H

include \$(BUILD_SHARED_LIBRARY)
EOF
    [ -f config.h ] || ./configure
    [ -f pnglibconf.h ] || make pnglibconf.h
    ndk-build NDK_PROJECT_PATH=. APP_BUILD_SCRIPT=Android.mk APP_PLATFORM=android-21 V=1
}

build_success() {
    success "build success. in $PWD/libs directory.\n"

    if command -v tree > /dev/null ; then
        tree "$PWD/libs"
    fi
}

main() {
    build "$@" && build_success
}

main "$@"
