#!/bin/sh

#===============下面的变量的取值根据自己的情况修改===============#

# 工程名称
PROJECT_NAME="newton"

# 生成的ipa文件的名称前缀
IPA_NAME=${PROJECT_NAME}_for_iOS;

# 钥匙串路径
LOGIN_KEYCHAIN=~/Library/Keychains/login.keychain

# 用户登陆密码
LOGIN_PASSWORD=xxxx

# P12文件路径
P12_PATH=个人_测试_证书.p12

# 开发者签名 
CODE_SIGN_IDENTITY="vvvvvv"

PROVISIONING_PROFILE=""

#================================================================#

# 导入证书
function importCer() {
    # 解锁，否则回弹框等待输入密码
    security unlock-keychain -p ${LOGIN_PASSWORD} ${LOGIN_KEYCHAIN}

    # 导入证书
    security import ${P12_PATH} -k ${LOGIN_KEYCHAIN} -P 111 -T /usr/bin/codesign
}

function runSonar() {
    # 导入证书
    importCer

    filepath=${PROJECT_NAME}.xcodeproj/project.pbxproj
                
    functhParam() {
        orgin=$(grep -i -n $1 $filepath | head -n 1 | awk -F ':' '{print $1}')
        count=$(grep -i -A 200 $1 $filepath | grep -i -n 'PROVISIONING_PROFILE' | head -n 1 |awk -F ':' '{print $1}')
        let line=$orgin+count-1
        echo $line
        sed -i '' $line"s/^.*/$2/g" $filepath
    }

    # 修改配置
    functhParam "^.*332573121A2EFCC30002ECA1.*=" 'PROVISIONING_PROFILE = "47f32d57-cead-47d8-aeab-67127c65ca83";'
    functhParam "^.*332573131A2EFCC30002ECA1.*=" 'PROVISIONING_PROFILE = "47f32d57-cead-47d8-aeab-67127c65ca83";'
    functhParam "^.*332573151A2EFCC30002ECA1.*=" 'PROVISIONING_PROFILE = "47f32d57-cead-47d8-aeab-67127c65ca83";'
    functhParam "^.*332573161A2EFCC30002ECA1.*=" 'PROVISIONING_PROFILE = "47f32d57-cead-47d8-aeab-67127c65ca83";'
    functhParam "^.*332573181A2EFCC30002ECA1.*=" 'PROVISIONING_PROFILE = "47f32d57-cead-47d8-aeab-67127c65ca83";'
    functhParam "^.*332573191A2EFCC30002ECA1.*=" 'PROVISIONING_PROFILE = "47f32d57-cead-47d8-aeab-67127c65ca83";'

    open ${PROJECT_NAME}.xcworkspace
    sleep 10

    # 编译
    xcodebuild -workspace ${PROJECT_NAME}.xcworkspace -scheme ${PROJECT_NAME} clean build | tee xcodebuild.log | xcpretty -t -r json-compilation-database -o compile_commands.json
    oclint-json-compilation-database -e Pods -e ${PROJECT_NAME}/Vendors -v -- -report-type pmd -o sonar-reports/oclint.xml
    current_date=`date +%Y%m%d`;
    echo current_date=$current_date

    sed -i "s#[0-9]\{8\}#${current_date}#g" sonar-project.properties
    
    sonar-runner
}

function runBuild() {
    MODE=$1;

    current_date=`date +%Y%m%d`;
    echo current_date=$current_date

    # 导入证书
    importCer

    filepath=${PROJECT_NAME}.xcodeproj/project.pbxproj

    functhParam() {
        orgin=$(grep -i -n $1 $filepath | head -n 1 | awk -F ':' '{print $1}')
        count=$(grep -i -A 200 $1 $filepath | grep -i -n 'PROVISIONING_PROFILE' | head -n 1 |awk -F ':' '{print $1}')
        let line=$orgin+count-1
        echo $line
        sed -i '' $line"s/^.*/$2/g" $filepath
    }

    functhParam2() {
        orgin=$(grep -i -n $1 $filepath | head -n 1 | awk -F ':' '{print $1}')
        count=$(grep -i -A 200 $1 $filepath | grep -i -n 'CODE_SIGN_IDENTITY' | head -n 1 |awk -F ':' '{print $1}')
        let line=$orgin+count-1
        echo $line
        sed -i '' $line"s/^.*/$2/g" $filepath
    }

    functhParam3() {
        orgin=$(grep -i -n $1 $filepath | head -n 1 | awk -F ':' '{print $1}')
        count=$(grep -i -A 200 $1 $filepath | grep -i -n '\"CODE_SIGN_IDENTITY\[sdk=iphoneos\*\]\"' | head -n 1 |awk -F ':' '{print $1}')
        let line=$orgin+count-1
        echo $line
        sed -i '' $line"s/^.*/$2/g" $filepath
    }

    # 修改配置
    functhParam "^.*332573121A2EFCC30002ECA1.*=" 'PROVISIONING_PROFILE = "47f32d57-cead-47d8-aeab-67127c65ca83";'
    functhParam "^.*332573131A2EFCC30002ECA1.*=" 'PROVISIONING_PROFILE = "47f32d57-cead-47d8-aeab-67127c65ca83";'
    functhParam "^.*332573151A2EFCC30002ECA1.*=" 'PROVISIONING_PROFILE = "47f32d57-cead-47d8-aeab-67127c65ca83";'
    functhParam "^.*332573161A2EFCC30002ECA1.*=" 'PROVISIONING_PROFILE = "47f32d57-cead-47d8-aeab-67127c65ca83";'
    functhParam "^.*332573181A2EFCC30002ECA1.*=" 'PROVISIONING_PROFILE = "47f32d57-cead-47d8-aeab-67127c65ca83";'
    functhParam "^.*332573191A2EFCC30002ECA1.*=" 'PROVISIONING_PROFILE = "47f32d57-cead-47d8-aeab-67127c65ca83";'

    functhParam2 "^.*332573151A2EFCC30002ECA1.*=" 'CODE_SIGN_IDENTITY = "${CODE_SIGN_IDENTITY}";'
    functhParam2 "^.*332573161A2EFCC30002ECA1.*=" 'CODE_SIGN_IDENTITY = "${CODE_SIGN_IDENTITY}";'
    functhParam2 "^.*332573181A2EFCC30002ECA1.*=" 'CODE_SIGN_IDENTITY = "${CODE_SIGN_IDENTITY}";'
    functhParam2 "^.*332573191A2EFCC30002ECA1.*=" 'CODE_SIGN_IDENTITY = "${CODE_SIGN_IDENTITY}";'

    functhParam3 "^.*332573151A2EFCC30002ECA1.*=" '"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "${CODE_SIGN_IDENTITY}";'
    functhParam3 "^.*332573161A2EFCC30002ECA1.*=" '"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "${CODE_SIGN_IDENTITY}";'
    functhParam3 "^.*332573181A2EFCC30002ECA1.*=" '"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "${CODE_SIGN_IDENTITY}";'
    functhParam3 "^.*332573191A2EFCC30002ECA1.*=" '"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "${CODE_SIGN_IDENTITY}";'


    appInfoPList=${PROJECT_NAME}/Info.plist
    # 取版本号
    bundleShortVersion=$(/usr/libexec/PlistBuddy -c "print CFBundleShortVersionString" ${appInfoPList})
    # 取build值
    bundleVersion=$(/usr/libexec/PlistBuddy -c "print CFBundleVersion" ${appInfoPList})
    # 取displayName
    displayName=$(/usr/libexec/PlistBuddy -c "print CFBundleDisplayName" ${appInfoPList})
    # IPA名称
    ipaName=${IPA_NAME}_${bundleVersion}_$(date +"%Y%m%d").ipa
    echo $ipaName

    open ${PROJECT_NAME}.xcworkspace
    sleep 10

    # 编译
    xcodebuild -workspace ${PROJECT_NAME}.xcworkspace -scheme ${PROJECT_NAME} -configuration ${MODE} -sdk "iphoneos9.3" VALID_ARCHS="arm64 armv7 armv7s" CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" PROVISIONING_PROFILE="${PROVISIONING_PROFILE}" CONFIGURATION_BUILD_DIR=`pwd`/build clean build
    xcrun -sdk iphoneos PackageApplication -v `pwd`/build/${PROJECT_NAME}.app -o `pwd`/build/${ipaName}
}

function showHelp() {
    echo "Usage:"
    echo "./tool.sh -h|--help       display help"
    echo "./tool.sh sonar           check you oc language with SonarQube"
    echo "./tool.sh build Debug     generate debug ipa"
    echo "./tool.sh build Release   generate release ipa"
}

#正文
if [ -z "$1" ] ; then
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
