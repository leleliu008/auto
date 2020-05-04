#/bin/sh

#注意：请将此脚本放置于源码根目录下
#参考：http://blog.fpliu.com/it/software/qrencode#build-with-ndk
#依赖：libpng
#参数: LIB_PNG_INCLUDES_DIR=some/path  LIB_PNG_LIBS_DIR=some/path

LIB_PNG_INCLUDES_DIR=$HOME/libpng-1.6.36/output/armv7a-linux-androideabi/21/include
LIB_PNG_LIBS_DIR=$HOME/libpng-1.6.36/output/armv7a-linux-androideabi/21/lib

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

LOCAL_MODULE    := qrencode
LOCAL_SRC_FILES := \$(shell ls *.c | awk '{gsub("qrenc.c", "");print}')

LOCAL_LDFLAGS   += -L$LIB_PNG_LIBS_DIR
LOCAL_LDLIBS    += -lpng

LOCAL_C_INCLUDES += $LIB_PNG_INCLUDES_DIR
LOCAL_CFLAGS     += -Os -v -DHAVE_CONFIG_H

include \$(BUILD_SHARED_LIBRARY)
EOF
    [ -f config.h ] || ./configure
    ndk-build NDK_PROJECT_PATH=. APP_BUILD_SCRIPT=Android.mk APP_PLATFORM=android-21 APP_ABI=armeabi-v7a
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
