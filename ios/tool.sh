#!/bin/sh

#================================================================#
#将此脚本放置于您的iOS WorkSpace或Project的根目录下


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
SDK='iphoneos13.1'

#================================================================#

currentScriptDir=$(cd "$(dirname "$0")" || exit; pwd)

Color_Purple='\033[0;35m'       # Purple
Color_Off='\033[0m'             # Reset

msg() {
    printf "%b\n" "$1"
}

info() {
    msg "${Color_Purple}[❉]${Color_Off} $1$2"
}

# 钥匙串路径
LOGIN_KEYCHAIN=~/Library/Keychains/login.keychain

# 导入P12文件
importP12() {
    # 解锁，否则系统会弹框等待用户输入密码
    security unlock-keychain -p ${LOGIN_PASSWORD} ${LOGIN_KEYCHAIN}

    # 导入证书
    security import ${P12_PATH} -k ${LOGIN_KEYCHAIN} -P ${P12_PASSWORD} -T /usr/bin/codesign
}

#把设备描述文件复制到指定目录下
cpProvisioningProfile() {
    tmpFile=$(mktemp)
    security cms -D -i $PROVISIONING_PROFILE_PATH > "$tmpFile" 2> /dev/null
    provisioningProfileUUID=$(getValueFromPListFile "$tmpFile" UUID)
    rm -f "$tmpFile"
    cp "$PROVISIONING_PROFILE_PATH" "$HOME/Library/MobileDevice/Provisioning Profiles/${provisioningProfileUUID}.mobileprovision"
}

#从plist文件中获取指定Key的值
#$1是plist文件路径
#$2是key
getValueFromPListFile() {
    /usr/libexec/PlistBuddy -c "print $2" "$1"
}

initVslues() {
    currentDate=$(date +%Y%m%d)
    info "currentDate : $currentDate"

    workspace=$(find . -name "*.xcworkspace" -d 1)
    
    if [ -z "$workspace" ] ; then
        project=$(find . -name "*.xcodeproj" -d 1)
        appName=$(basename "$project" .xcodeproj)
        info "project     : $project"
        info "appName     : $appName"
    else
        appName=$(basename "$workspace" .xcworkspace)
        info "workspace   : $workspace"
        info "appName     : $appName"
    fi
}

check() {
    [ -z "$LOGIN_PASSWORD" ] && error "LOGIN_PASSWORD isn't config"
    [ -z "$P12_PATH" ] && error "P12_PATH isn't config"
    [ -z "$P12_PASSWORD" ] && error "P12_PASSWORD isn't config"
    [ -z "$PROVISIONING_PROFILE_PATH" ] && error "PROVISIONING_PROFILE_PATH isn't config"
    [ -z "$SDK" ] && error "SDK isn't config"
}

# 运行静态代码检测
runSonar() {
    check

    # 导入证书
    importP12

    # 把设备描述文件放到指定目录下
    cpProvisioningProfile
    
    # 编译
    xcodebuild -workspace "$workspace" -scheme "$appName" clean build | tee xcodebuild.log | xcpretty -t -r json-compilation-database -o compile_commands.json
    oclint-json-compilation-database -e Pods -e "${appName}/Vendors" -v -- -report-type pmd -o sonar-reports/oclint.xml
    
    sed -i  "" "s/[0-9]\{8\}/${currentDate}/g" sonar-project.properties
    
    sonar-runner
}

# 构建
# $1构建类型：Debug、Release
runBuild() {
    check

    # 导入证书
    importP12
    
    # 把设备描述文件放到指定目录下
    cpProvisioningProfile
    
    appInfoPList=${appName}/Info.plist
    
    # 取版本号
    versionName=$(getValueFromPListFile "$appInfoPList" CFBundleShortVersionString)
    
    # IPA名称
    ipaName=${appName}_${versionName}_$(date +%Y%m%d).ipa
    
    # 获得证书签名
    codeSignIdentity=$(openssl pkcs12 -in $P12_PATH -passin pass:"$P12_PASSWORD" -nodes | grep "friendlyName: iPhone")
    codeSignIdentity=$(printf "%s\n" "$codeSignIdentity" | awk '{ string=substr($0, 19, length); print string }')
    
    buildPath="$currentScriptDir/build"
    archivePath="${buildPath}/${appName}.xcarchive"
   
    info "ipaName     : $ipaName"
    
    # 编译并归档
    xcodebuild \
            -workspace "$workspace" \
            -scheme "$appName" \
            -configuration "$1" \
            -sdk "$SDK" \
            -archivePath "$archivePath" \
            CODE_SIGN_STYLE=Automatic \
            CODE_SIGN_IDENTITY="$codeSignIdentity" \
            PROVISIONING_PROFILE="$provisioningProfileUUID" \
            CONFIGURATION_BUILD_DIR="$buildPath" \
            VALID_ARCHS="arm64 armv7 armv7s" \
            clean archive
    # 打包ipa
    xcodebuild -exportArchive -archivePath "$archivePath" -exportOptionsPlist archive.plist -exportPath "$ipaName"
}

showHelp() {
    cat <<EOF
Usage:
./tool.sh -h              display help
./tool.sh --help          display help
./tool.sh sonar           check you oc language with SonarQube
./tool.sh build Debug     generate debug ipa
./tool.sh build Release   generate release ipa
EOF
}

main() {
    [ "$(uname -s)" = 'Darwin' ] || error "your os is not MacOSX!"
    
    initVslues

    if [ "$1" = 'sonar' ] ; then
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

main "$@"
