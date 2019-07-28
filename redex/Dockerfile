FROM ubuntu:18.04

MAINTAINER 792793182@qq.com

# Android SDK Tools下载地址：https://developer.android.google.cn/studio
RUN rm /etc/apt/sources.list && \
    echo "deb http://mirrors.aliyun.com/ubuntu/ bionic main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb http://mirrors.aliyun.com/ubuntu/ bionic-security main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb http://mirrors.aliyun.com/ubuntu/ bionic-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb http://mirrors.aliyun.com/ubuntu/ bionic-proposed main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb http://mirrors.aliyun.com/ubuntu/ bionic-backports main restricted universe multiverse" >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y curl unzip openjdk-8-jdk git make g++ automake autoconf autoconf-archive libtool libboost-all-dev liblz4-dev liblzma-dev zlib1g-dev binutils-dev libjemalloc-dev libiberty-dev libjsoncpp-dev && \
    apt-get clean && \
    rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    mkdir -p /usr/local/share/android-sdk && \
    cd /usr/local/share/android-sdk && \
    curl -LO https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip && \
    unzip sdk-tools-linux-4333796.zip && \
    rm sdk-tools-linux-4333796.zip && \
    cd tools/bin && \
    echo y | ./sdkmanager "platforms;android-28" && \
    echo y | ./sdkmanager "platform-tools" && \
    echo y | ./sdkmanager "build-tools;28.0.3" && \
    git clone https://github.com/facebook/redex.git && \
    cd redex && \
    autoreconf -ivf && \
    ./configure && \
    make && \
    make install && \
    cd .. && \
    rm -rf redex

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV ANDROID_HOME /usr/local/share/android-sdk
ENV PATH ${PATH}:${ANDROID_HOME}/tools:${ANDROID_HOME}/tools/bin:${ANDROID_HOME}/platform-tools
ENV LANG C.UTF-8

CMD [ "bash" ]
