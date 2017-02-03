#!/bin/bash
#------------------------------------------------------------------------------#
# Android客户端构建、测试相关工具
# 注意，使用了ANDROID_HOME环境变量，如果没有配置，请先配置
#-----------------------下面的变量可以根据情况修改-----------------------------#

appName='Newton_for_Android';
packageName='com.fpliu.newton';

android_sdk_framework_version=23
android_sdk_build_tools_version=23.0.3

keystore_path=keystore.jks
keystore_password=123456
keystore_alias_name=newton

svnApkRepoUrl=
svnTagRepoUrl=
svnBranchRepoUrl=

#------------------------------------------------------------------------------#

currentDate=`date +%Y%m%d`;
echo "currentDate=$currentDate"

osType=`uname -s`
echo "osType=$osType"

#从主工程的AndroidManifest.xml中获取Apk的版本名称
#使用``或者$()取得值
function getVersionNameFromManifest() {
    versionName=`cat AndroidManifest.xml | grep 'versionName="[^"]*"' | sed 's/.*versionName="\([^"]*\)".*/\1/'`
    echo "${versionName}"
}

#从主工程的build.gradle中读取版本名
#使用``或者$()取得值
function getVersionNameFromBuildGradle() {
    versionName=`cat build.gradle | grep 'versionName "[^"]*"' | sed 's/versionName "\([^"]*\)".*/\1/'`
    echo "${versionName}"
}

#更新Android SDK
function updateAndroidSDK() {
    echo y | android update sdk --no-ui --all --filter android-${android_sdk_framework_version},platform-tools,build-tools-${android_sdk_build_tools_version},extra-android-m2repository
}

#执行单元测试
function testWithUnit() {
    adb shell am instrument -w ${packageName}.test/android.test.InstrumentationTestRunner
}

#执行Monkey测试
function testWithMonkey() {
    adb shell monkey -p ${packageName} -vvv 20000
}

#执行SonarQube代码扫描
function runSonarScanner() {
    if [ $osType = 'Darwin' ] ; then
    	sed -i ""  "s#[0-9]\{8\}#${currentDate}#g" sonar-project.properties
    else
    	sed -i "s#[0-9]\{8\}#${currentDate}#g" sonar-project.properties
    fi

    ./gradlew lint && sonar-runner
}

#安装编译好的应用
function installApk() {
    adb install -r *.apk
}

#卸载当前设备上的应用
function uninstallApk() {
    adb uninstall ${packageName}
}

#显示签名的MD5
function showMD5() {
    keytool -list -v -keystore ${keystore_path} -storepass ${keystore_password} -alias ${keystore_alias_name}
}

# 删除apk中的签名信息
# $1 是apk的路径
function removeSignInfo() {
    aapt r "$1" META-INF/CERT.SF
    aapt r "$1" META-INF/CERT.RSA
    aapt r "$1" META-INF/MANIFEST.MF
}

# 给Apk签名
# $1 如果为空，就是当前目录中生成的apk，
# $1 如果指定了路径，就使用指定路径的apk
function signApk() {
    if [ -z "$1" ] ; then
        apkName=`ls *.apk | head -n 1`
        echo "apkName=${apkName}"

        if [ -z "$apkName" ] ; then
            echo "no apk generated in project!"
            exit 1
        fi

        apkNamePrefix=`basename ${apkName} .apk`
        echo "apkNamePrefix=${apkNamePrefix}"
        
        removeSignInfo ${apkName}
    	jarsigner -verbose -keystore ${keystore_path} -storepass ${keystore_password} -digestalg SHA1 -sigalg MD5withRSA -sigfile CERT -signedjar ${apkNamePrefix}_signed.apk "$apkName" ${keystore_alias_name}
    else
        if [ -f "$1" ] ; then
            unzip -t "$1" >& /dev/null
            if [ $? -eq 0 ] ; then
                removeSignInfo ${apkName}

                apkNamePrefix=`basename "$1" .apk`
    	        jarsigner -verbose -keystore ${keystore_path} -storepass ${keystore_password} -digestalg SHA1 -sigalg MD5withRSA -sigfile CERT -signedjar ${apkNamePrefix}_signed.apk "$1" ${keystore_alias_name}
            else
                echo "$1 is not a apk file!"
            fi
        else
            echo "$1 is not exsit!"
            exit 1
        fi
    fi
}

# 对Apk进行字节对齐优化
# $1 如果为空，表示对当前工程中的对齐
function alignApk() {
    if [ -z "$1" ] ; then
        apkName=`ls *_signed.apk | head -n 1`
        if [ -z "$apkName" ] ; then
            echo "no signed apk generated in project!"
            exit 1
        fi

        zipalign -v -f 4 ${apkName} $(basename ${apkName} .apk)_aligned.apk
    else
        if [ -f "$1" ] ; then
            unzip -t "$1" >& /dev/null
            if [ $? -eq 0 ] ; then
                zipalign -v -f 4 $1 $(basename ${apkName} .apk)_aligned.apk
            else
                echo "$1 is not a apk file!"
            fi
        else
            echo "$1 is not exsit!"
            exit 1
        fi
    fi
}

#显示Apk的版本名称
function showApkVersion() {
    aapt dump badging *.apk | grep "version"
}

#打开Genymotion模拟器
function openGenymotion() {
    player --vm-name "Google Nexus 5 - 4.4.4 - API 19 - 1080x1920" &
}

#SVN操作
function runSVN() {
    if [ "$1" = 'getApkRepoUrl' ] ; then
    	echo "svnApkRepoUrl=$svnApkRepoUrl"
    elif [ "$1" = 'getTagRepoUrl' ] ; then
        echo "svnTagRepoUrl=$svnTagRepoUrl"
    elif [ "$1" = 'getBranchRepoUrl' ] ; then
        echo "svnBranchRepoUrl=$svnBranchRepoUrl"
    elif [ "$1" = 'listApkRepo' ] ; then
        svn ls $svnApkRepoUrl
    elif [ "$1" = 'listTagRepo' ] ; then
        svn ls $svnTagRepoUrl
    elif [ "$1" = 'listBranchRepo' ] ; then
        svn ls $svnBranchRepoUrl
    elif [ "$1" = 'uploadApk' ] ; then
        for apkFile in `ls *.apk`
	    do
            remoteApk=${svnApkRepoUrl}/${apkFile}
    	    echo "remoteApk=$remoteApk"

    	    svn info ${remoteApk} >& /dev/null
    	    if [ $? -eq 0 ] ; then
    		    svn delete ${remoteApk} -m "re commit, so delete"
    		    echo ${apkFile}" exsit at remote, re commit, so delete"
    	    fi

    	    svn import ${apkFile} ${remoteApk} -m "commit"
    	    echo "import success"
	    done
    elif [ $1 = 'makeTag' ] ; then
        echo "-------------------clean begin---------------------"
        rm -f `find ./ -name "*.iml"`
        rm -f `find ./ -name "build"`
        rm -rf .gradle/
        rm -f *.apk
        echo "-------------------clean end---------------------"

        read -p "please input tagName:" tagName

        echo "-------------------upload begin---------------------"
        svn import . ${svnTagRepoUrl}/${tagName} -m "commit" --no-ignore
        echo "-------------------upload end---------------------"
    else
    	echo "$1 not support"
    fi
}

# 替换local.properties中的Android SDK路径
function setAndroidSDKHomeInLocalProperties() {
    if [ -z "$ANDROID_HOME" ] ; then
        echo "[warning]:please config ANDROID_HOME environment first!"
        exit 1
    fi

    if [ $osType = 'Darwin' ] ; then
        sed -i ""  "s#sdk\.dir=.*#sdk.dir=${ANDROID_HOME}#g" `find ./ -name "local.properties"`
    else
        sed -i "s#sdk\.dir=.*#sdk.dir=${ANDROID_HOME}#g" `find ./ -name "local.properties"`
    fi
}

# 替换build.gradle里面的版本号（versionCode）
# $1是版本号
function setVersionCodeInBuildGradle() {
    if [ $osType = 'Darwin' ] ; then
        sed -i ""  "s#versionCode [0-9]\{8\}#versionCode $1#g" build.gradle
    else
        sed -i "s#versionCode [0-9]\{8\}#versionCode $1#g" build.gradle
    fi
}

# 替换build.gradle里面的包号（applicationId）
function setPackageNameInBuildGradle() {
    if [ $osType = 'Darwin' ] ; then
        sed -i ""  "s#applicationId \".*\"#applicationId \"${packageName}\"#g" build.gradle
    else
        sed -i "s#applicationId \".*\"#applicationId \"${packageName}\"#g" build.gradle
    fi
}

# 修改AndroidManifest.xml里面的android:debuggable开关
# $1 为true | false字符串
function setDebugable() {
    origin="true"
    xx="false"
    if [ $1 ] ; then
        origin="false"
        xx="true"
    else
        origin="true"
        xx="false"
    fi

    if [ $osType = 'Darwin' ] ;then
        sed -i ""  "s#android:debuggable=\"${origin}\"#android:debuggable=\"${xx}\"#g" src/main/AndroidManifest.xml
    else
        sed -i "s#android:debuggable=\"${origin}\"#android:debuggable=\"${xx}\"#g" src/main/AndroidManifest.xml
    fi
}

# 设置环境
# $1为 debug | release | develop | demo
# $2为要设置的Java类的路径
function setEnvInJava() {
    if [ $osType = 'Darwin' ] ; then
        sed -i ""  "s#Environment\.[a-z]*#Environment.$1#g" "$2"
    else
        sed -i "s#Environment\.[a-z]*#Environment.$1#g" "$2"
    fi
}

# 修改环境 
# $1取值为 debug | release | develop | demo
function changeEnvTo() {
    setAndroidSDKHomeInLocalProperties

    setVersionCodeInBuildGradle ${currentDate}
    setPackageNameInBuildGradle

    #修改Debug开关
    if [ "$1" = "release" ] ; then
        setDebugable false
    else
        setDebugable true
    fi

    packagePath=${packageName//.//}
    echo "packagePath = $packagePath"

    setEnvInJava "$1" src/main/java/${packagePath}/config/Config.java
}

# 编译后的apk名称
# $1取值为 debug | release | develop | demo
function getApkName() {
    versionName=`getVersionNameFromBuildGradle`
    apkName=${appName}_`echo ${versionName}`_${currentDate}_$1_member.apk
    echo "${apkName}"
}

# 执行编译
# $1取值为 debug | release | develop | demo
function runBuild() {
    changeEnvTo $1

    ./gradlew clean
    if [ "$1" = "release" ] ; then
        ./gradlew assembleRelease

        if [ $? -eq 0 ] ; then
    		rm -f *.apk
            cp build/outputs/apk/$(basename `pwd`)-release.apk `getApkName $1`
        else
            exit 1
        fi
    else
        ./gradlew assembleDebug

        if [ $? -eq 0 ] ; then
    		rm -f *.apk;
            cp build/outputs/apk/$(basename `pwd`)-debug.apk `getApkName $1`
        else
            exit 1
        fi
    fi
}

# 显示帮助
function showHelp() {
	echo "Usage:"
	echo "tool.sh <sub-cmd> [sub-sub-cmd]"
	echo ""
	echo "sub-command:"
	echo "test build check install uninstall show-md5"
	echo ""
	echo "examples:"
	echo "tool.sh test unit      execute unit test"
	echo "tool.sh test monkey    execute monkey test"
	echo "tool.sh sonar          execute sonar scanner"
	echo "tool.sh show-md5       show your keystore's md5"
	echo "tool.sh build debug    build debug environment apk"
	echo "tool.sh build release  build release environment apk"
	echo "tool.sh install        install the builded apk"
	echo "tool.sh uninstall      uninstall my apk"
	echo "tool.sh sign           sign my apk"
	echo "tool.sh sign ~/xx.apk  sign ~/xx.apk"
	echo "tool.sh signAlign      sign and align my apk"
	echo "tool.sh signAlign ~/xx.apk  sign and align ~/xx.apk"
	echo "tool.sh align          align my apk"
	echo "tool.sh check version  get the apk versionCode and versionName"
    
    exit 1
}

#正文开始
if [ -z "$1" ] ; then
    showHelp
elif [ "$1" = "-h" ] || [ "$1" = "--help" ] ; then
	showHelp
elif [ "$1" = 'test' ] ; then
    if [ "$2" = 'unit' ] ; then
		testWithUnit
	elif [ "$2" = 'monkey' ] ; then
		testWithMonkey
	fi
elif [ "$1" = 'sonar' ] ; then
	runSonarScanner
elif [ "$1" = 'show-md5' ] ; then
	showMD5
elif [ "$1" = 'check' ] ; then
	if [ "$2" = 'version' ] ; then
	    showApkVersion
	fi
elif [ "$1" = 'install' ] ; then
	installApk
elif [ "$1" = 'uninstall' ] ; then
	uninstallApk
elif [ "$1" = 'sign' ] ; then
	signApk "$2"
elif [ "$1" = 'align' ] ; then
	alignApk
elif [ "$1" = 'signAlign' ] ; then
	signApk "$2" && alignApk
elif [ "$1" = 'genymotion' ] ; then
	openGenymotion
elif [ "$1" = 'svn' ] ; then
    if [ -z "$2" ] ; then
        showHelp
    else
        runSVN "$2"
    fi
elif [ "$1" = 'changeEnvTo' ] ; then
    if [ -z "$2" ] ; then
        showHelp
    else
        changeEnvTo "$2"
    fi
elif [ $1 = 'build' ] ; then
    if [ -z "$2" ] ; then
        showHelp
    else
		runBuild "$2"
    fi
else
    echo "unrecognized sub-cmd "$1"!"
    exit 1
fi
