#!/bin/sh

##########################################################
#注意：请将此脚本放置于源码根目录下
#参考：http://blog.fpliu.com/it/software/development/language/C/library/Ne10/build-for-android-with-cmake
##########################################################


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
    case "$TARGET_ABI" in
        armeabi-v7a) TARGET_ARCH_ABI=armv7;;
        arm64-v8a)   TARGET_ARCH_ABI=aarch64;;
    esac

    cmake \
    -DCMAKE_TOOLCHAIN_FILE="${ANDROID_NDK_HOME}/build/cmake/android.toolchain.cmake" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_NDK_BUILD_DIR/${TARGET_ABI}" \
    -DNE10_BUILD_SHARED=ON \
    -DNE10_BUILD_EXAMPLES=OFF \
    -DNE10_ANDROID_TARGET_ARCH="$TARGET_ARCH_ABI" \
    -DANDROID_PLATFORM=ON \
    -DANDROID_TOOLCHAIN=clang \
    -DANDROID_ABI="${TARGET_ABI}" \
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
    for TARGET_ABI in armeabi-v7a arm64-v8a
    do
        info "Building Ne10 for ${TARGET_ABI}"
        build || exit
    done
    build_success
}

main
