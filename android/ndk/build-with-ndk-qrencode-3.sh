#!/bin/sh

###################################################################
#注意：请将此脚本放置于源码根目录下
#参考：http://blog.fpliu.com/it/software/qrencode/build-for-android-with-cmake
###################################################################

LIB_PNG_NDK_BUILD_DIR="$HOME/libpng-1.6.36/ndk-build"

INSTALL_NDK_BUILD_DIR="$PWD/ndk-build"

Color_Green='\033[0;32m'        # Green
Color_Purple='\033[0;35m'       # Purple
Color_Off='\033[0m'             # Reset

msg() {
    printf "%b\n" "$@"
}

info() {
    msg "${Color_Purple}[❉] $@${Color_Off}"
}

success() {
    msg "${Color_Green}[✔] $@${Color_Off}"
}

nproc() {
    if command -v nproc > /dev/null ; then
        command nproc
    elif command -v sysctl > /dev/null ; then
        sysctl -n machdep.cpu.thread_count
    elif test -f /proc/cpuinfo ; then
        grep -c processor /proc/cpuinfo
    else
        printf "%b" 4
    fi
}

build() {
    cmake \
    -DCMAKE_TOOLCHAIN_FILE="${ANDROID_NDK_HOME}/build/cmake/android.toolchain.cmake" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_NDK_BUILD_DIR/${TARGET_ABI}" \
    -DBUILD_SHARED_LIBS=ON \
    -DANDROID_TOOLCHAIN=clang \
    -DANDROID_ABI="${TARGET_ABI}" \
    -DPNG_PNG_INCLUDE_DIR="$LIB_PNG_NDK_BUILD_DIR/$TARGET_ABI/include" \
    -DPNG_LIBRARY_RELEASE="$LIB_PNG_NDK_BUILD_DIR/$TARGET_ABI/lib/libpng.so"
    -G "Unix Makefiles" \
    -Wno-dev \
    -S . \
    -B "build/${TARGET_ABI}" && \
    make --directory="build/${TARGET_ABI}" -j$(nproc) && \
    make --directory="build/${TARGET_ABI}" install
}

build_success() {
    success "build success. in $INSTALL_NDK_BUILD_DIR directory."

    if command -v tree > /dev/null ; then
        tree -L 3 "$INSTALL_NDK_BUILD_DIR"
    fi
}

main() {
    for TARGET_ABI in armeabi-v7a arm64-v8a x86 x86_64
    do
        info "Building libogg for ${TARGET_ABI}"
        build || exit
    done
    build_success
}

main
