# ------------------------------------------------------- #
# Android环境搭建的Docker容器构建脚本
# 
# JDK下载地址：
# http://www.oracle.com/technetwork/java/javase/downloads/index.html
#
# Android SDK 和 Android Studio 的最新信息，请查看：
# https://developer.android.google.cn/studio/index.html
# ------------------------------------------------------- #

FROM ubuntu:16.04

MAINTAINER leleliu008@gmail.com

ENV WORK_DIR /opt
ENV JAVA_HOME ${WORK_DIR}/jdk1.8.0_65
ENV JDK_FILENAME jdk-8u65-linux-x64.tar.gz
ENV JDK_URL http://download.oracle.com/otn-pub/java/jdk/8u65-b17/${JDK_FILENAME}

ENV ANDROID_HOME ${WORK_DIR}/android-sdk-linux
ENV ANDROID_SDK_FILENAME android-sdk_r24.4.1-linux.tgz
ENV ANDROID_SDK_URL http://dl.google.com/android/${ANDROID_SDK_FILENAME}
ENV ANDROID_SDK_FRAMEWORK_VERSION 23
ENV ANDROID_SDK_BUILD_TOOLS_VERSION 23.0.2

ENV PATH ${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/build-tools/${ANDROID_SDK_BUILD_TOOLS_VERSION}:${JAVA_HOME}/bin/

# 更新软件库，安装依赖库和依赖工具
RUN \
    apt-get update && \
    apt-get install -y gcc-multilib lib32z1 lib32stdc++6 && \
    apt-get install -y git subversion vim curl wget openssh-server &&\
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 下载JDK，并解压缩
RUN \
    cd ${WORK_DIR} && \
    wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" ${JDK_URL} && \
    tar xf ${JDK_FILENAME} && \
    rm -rf ${JAVA_HOME}/src.zip && \
    rm -rf ${JAVA_HOME}/javafx-src.zip && \
    rm -rf ${JAVA_HOME}/man && \
    rm -rf ${JDK_FILENAME}

# 下载Android SDK，并解压缩
RUN \
    cd ${WORK_DIR} && \
    wget ${ANDROID_SDK_URL} && \
    tar -xzf ${ANDROID_SDK_FILENAME} && \
    rm ${ANDROID_SDK_FILENAME}

# 更新Android SDK
RUN \
    echo y | android update sdk --no-ui --all --filter android-${ANDROID_SDK_FRAMEWORK_VERSION},platform-tools,build-tools-${ANDROID_SDK_BUILD_TOOLS_VERSION},extra-android-m2repository

# 让此容器一直运行下去
ENTRYPOINT ["/usr/sbin/sshd"]
CMD ["-D"]
