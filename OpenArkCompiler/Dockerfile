FROM ubuntu:16.04

MAINTAINER 792793182@qq.com

RUN rm /etc/apt/sources.list && \
    echo "\
deb http://mirrors.huaweicloud.com/ubuntu/ bionic main restricted universe multiverse\n\
deb http://mirrors.huaweicloud.com/ubuntu/ bionic-security main restricted universe multiverse\n\
deb http://mirrors.huaweicloud.com/ubuntu/ bionic-updates main restricted universe multiverse\n\
deb http://mirrors.huaweicloud.com/ubuntu/ bionic-proposed main restricted universe multiverse\n\
deb http://mirrors.huaweicloud.com/ubuntu/ bionic-backports main restricted universe multiverse" \
>> /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y curl tar gzip openjdk-8-jdk && \
    apt-get clean && \
    rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    curl -L https://www.openarkcompiler.cn/download/OpenArkCompiler-0.2-ubuntu-16.04-x86_64.tar.gz | tar zxv

WORKDIR /OpenArkCompiler-0.2-ubuntu-16.04-x86_64

ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV PATH ${PATH}:/OpenArkCompiler-0.2-ubuntu-16.04-x86_64/bin
ENV LANG C.UTF-8

CMD [ "bash" ]
