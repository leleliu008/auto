#!/bin/sh

#参考：http://blog.fpliu.com/it/software/SDL2/build-for-android-with-ndk-build

#后缀名必须是.tar.gz的那个
SOURCE_URL='https://www.libsdl.org/release/SDL2-2.0.12.tar.gz'
SOURCE_PATH=$HOME/SDL2-2.0.12

Color_Red='\033[0;31m'          # Red
Color_Green='\033[0;32m'        # Green
Color_Purple='\033[0;35m'       # Purple
Color_Off='\033[0m'             # Reset

msg() {
    printf "%b" "$1"
}

info() {
    msg "${Color_Purple}[❉] $@${Color_Off}"
}

success() {
    msg "${Color_Green}[✔] $@${Color_Off}"
}

error_exit() {
    msg "${Color_Red}[✘] $@${Color_Off}"
    exit 1
}

build() {
    ndk-build NDK_PROJECT_PATH="$SOURCE_PATH" APP_BUILD_SCRIPT="$SOURCE_PATH/Android.mk" APP_PLATFORM=android-21 V=1
}

download() {
    info "Downloading $SOURCE_URL...\n" &&
    curl -LO "$SOURCE_URL" &&
    success "Downloaded->$PWD/$FILE_NAME\n"
}

uncompress() {
    tar vxf "$FILE_NAME" && SOURCE_PATH="$PWD/$DIR_NAME"
}

build_success() {
    NDK_BUILD_DIR="$SOURCE_PATH/ndk-build"

    rm -rf "$NDK_BUILD_DIR" && 
    mkdir "$NDK_BUILD_DIR" && {
        for abi in armeabi-v7a arm64-v8a x86 x86_64
        do
            mkdir "$NDK_BUILD_DIR/$abi" &&
            ln -sf "$SOURCE_PATH/include/" "$NDK_BUILD_DIR/$abi/" &&
            ln -sf "$SOURCE_PATH/libs/$abi/" "$NDK_BUILD_DIR/$abi/lib"
        done
    } &&
    success "build success. in $NDK_BUILD_DIR directory.\n"
    
    if command -v tree > /dev/null ; then
        tree -l "$NDK_BUILD_DIR"
    fi
}

main() {
    if [ -n "$SOURCE_PATH" ] ; then
        if [ -d "$SOURCE_PATH" ] ; then
            build &&
            build_success
        else
            error_exit "$SOURCE_PATH is not a directory.\n"
        fi
    elif [ -n "$SOURCE_URL" ] ; then
        FILE_NAME="$(basename "$SOURCE_URL")"
        DIR_NAME="$(basename "$FILE_NAME" .tar.gz)"
        if [ -f "$FILE_NAME" ] ; then
            if tar -tf "$FILE_NAME" ; then
                uncompress &&
                build &&
                build_success
            else
                rm "$FILE_NAME" &&
                download &&
                uncompress &&
                build &&
                build_success
            fi
        else
            download &&
            uncompress &&
            build &&
            build_success
        fi
    else
        error_exit "please set SOURCE_URL or SOURCE_PATH variable.\n"
    fi
}

main
