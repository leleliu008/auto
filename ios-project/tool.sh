#!/bin/sh

#================================================================#
#将此脚本放置于您的iOS WorkSpace或Project的根目录下
#================================================================#


#===============下面的变量的取值根据自己的情况修改===============#
# 当前登陆用户的登录密码（导入P12文件的时候需要授权使用）
LOGIN_PASSWORD=

# P12文件路径（P12文件是用密码进行保护的，因为它里面包含有私钥）
P12_PATH=ios_development.p12

# P12文件的访问密码
P12_PASSWORD=

# 设备描述文件路径
PROVISIONING_PROFILE_PATH=ios_provisioning_profile.mobileprovision

#使用的SDK和版本，用xcodebuild -showsdks可以查看到
SDK='iphoneos11.0'
#================================================================#

# 钥匙串路径
LOGIN_KEYCHAIN=~/Library/Keychains/login.keychain

# 导入P12文件
function importP12() {
    # 解锁，否则系统会弹框等待用户输入密码
    security unlock-keychain -p ${LOGIN_PASSWORD} ${LOGIN_KEYCHAIN}

    # 导入证书
    security import ${P12_PATH} -k ${LOGIN_KEYCHAIN} -P ${P12_PASSWORD} -T /usr/bin/codesign
}

# 运行静态代码检测
function runSonar() {
    # 导入证书
    importP12

    # 把设备描述文件放到指定目录下
    cpProvisioningProfile
    
    workspaceName=`find . -name "*.xcworkspace" -d 1`
    projectName=`basename $workspaceName .xcworkspace`
    
    # 编译
    xcodebuild -workspace ${workspaceName} -scheme ${projectName} clean build | tee xcodebuild.log | xcpretty -t -r json-compilation-database -o compile_commands.json
    oclint-json-compilation-database -e Pods -e ${projectName}/Vendors -v -- -report-type pmd -o sonar-reports/oclint.xml
    
    current_date=`date +%Y%m%d`;
    
    sed -i "s#[0-9]\{8\}#${current_date}#g" sonar-project.properties
    
    sonar-runner
}

# 构建
# $1构建类型：Debug、Release
function runBuild() {
    # 导入证书
    importP12
    
    # 把设备描述文件放到指定目录下
    security cms -D -i $PROVISIONING_PROFILE_PATH > tmp.xml 2> /dev/null
    uuid=`getValueFromPListFile tmp.xml UUID`
    rm tmp.xml
    cp $PROVISIONING_PROFILE_PATH ~/Library/MobileDevice/Provisioning\ Profiles/${uuid}.mobileprovision 
    
    workspaceName=`find . -name "*.xcworkspace" -d 1`
    projectName=`basename $workspaceName .xcworkspace`
    appInfoPList=${projectName}/Info.plist
    # 取版本号
    bundleShortVersion=`getValueFromPListFile ${appInfoPList} CFBundleShortVersionString`
    # 取build值
    bundleVersion=`getValueFromPListFile ${appInfoPList} CFBundleVersion`
    # IPA名称
    ipaName=${projectName}_${bundleVersion}_`date +%Y%m%d`.ipa
    
    # 获得证书签名
    codeSignIdentity=`openssl pkcs12 -in $P12_PATH -passin pass:"$P12_PASSWORD" -nodes | grep "friendlyName: iPhone"`
    codeSignIdentity=`echo ${codeSignIdentity:18}`

    configFile="${projectName}.xcodeproj/project.pbxproj"
    
    # 将设备描述文件自动管理改为手动管理
    #if [ `uname -s` == 'Darwin' ] ; then
    #    sed -i ""  "s#ProvisioningStyle = Automatic#ProvisioningStyle = Manual#g" $configFile
    #else
    #    sed -i "s#ProvisioningStyle = Automatic#ProvisioningStyle = Manual#g" $configFile
    #fi

    buildPath=`pwd`/build
    archivePath=${buildPath}/${projectName}.xcarchive
    # 编译
    xcodebuild \
            -workspace $workspaceName \
            -scheme ${projectName} \
            -configuration $1 \
            -sdk $SDK \
            -archivePath ${archivePath} \
            CODE_SIGN_STYLE=Manual \
            CODE_SIGN_IDENTITY="${codeSignIdentity}" \
            PROVISIONING_PROFILE="${uuid}" \
            CONFIGURATION_BUILD_DIR="${buildPath}" \
            VALID_ARCHS="arm64 armv7 armv7s"
            clean archive
    # 封包
    xcodebuild -exportArchive -archivePath $archivePath -exportOptionsPlist xx.plist -exportPath ${buildPath}
}

#把设备描述文件复制到指定目录下
function cpProvisioningProfile() {
    security cms -D -i $PROVISIONING_PROFILE_PATH > tmp.xml 2> /dev/null
    uuid=`getValueFromPListFile tmp.xml UUID`
    rm tmp.xml
    cp $PROVISIONING_PROFILE_PATH ~/Library/MobileDevice/Provisioning\ Profiles/${uuid}.mobileprovision  
}

#从plist文件中获取指定Key的值
#$1是plist文件路径
#$2是key
function getValueFromPListFile() {
    /usr/libexec/PlistBuddy -c "print $2" $1
}

function showHelp() {
    echo "Usage:"
    echo "./tool.sh -h              display help"
    echo "./tool.sh --help          display help"
    echo "./tool.sh sonar           check you oc language with SonarQube"
    echo "./tool.sh build Debug     generate debug ipa"
    echo "./tool.sh build Release   generate release ipa"
}

#正文
function main() {
    if [ `uname -s` != 'Darwin' ] ; then
        echo "your os is not MacOSX!"
        exit
    elif [ -z "$1" ] ; then
        showHelp
    elif [ "$1" = '-h' -o "$1" = '--help' ] ; then
        showHelp
    elif [ "$1" = 'sonar' ] ; then
        runSonar
    elif [ "$1" = 'build' ] ; then
        if [ -z "$2" ] ; then
            showHelp
        else
            runBuild "$2"
        fi
    else
        showHelp
    fi
}

main $*
