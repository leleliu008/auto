#!/bin/bash

#-------------- these config can be changed --------------
#appName如果不设置的话，使用当前文件夹的名字
appName=

#---------------------------------------------------------

Color_Red='\033[0;31m'          # Red
Color_Green='\033[0;32m'        # Green
Color_Yellow='\033[0;33m'       # Yellow
Color_Purple='\033[0;35m'       # Purple
Color_Off='\033[0m'             # Reset

msg() {
    printf "%b\n" "$1"
}

success() {
    msg "${Color_Green}[✔]${Color_Off} $1$2"
}

info() {
    msg "${Color_Purple}[❉]${Color_Off} $1$2"
}

warn() {
    msg "${Color_Yellow}[⌘]${Color_Off} $1$2"
}

error() {
    msg "${Color_Red}[✘]${Color_Off} $1$2"
    exit 1
}

errorOnly() {
    msg "${Color_Red}[✘]${Color_Off} $1$2"
}

#BSD sed与GNU sed在-i参数上的使用方法不一样
sedCompatible() {
    if [ "$osType" == "Darwin" ] ; then
    	sed -i ""  "$1" "$2"
    else
    	sed -i "$1" "$2"
    fi
}

initValues() {
    [ -z "$osType" ] && osType="$(uname -s)"
    info "osType        = $osType"
    
    [ "$(whoami)" == "root" ] || sudo=sudo
    info "whoami        = $(whoami)"
    
    [ -z "$workDir" ] && workDir="$(cd "$(dirname "$0")" || exit 1; pwd)"
    info "workDir       = $workDir"
}

readKeyStoreInfo() {
    [ -z "$storeFile" ] && {
        local buildScript="$workDir/app/build.gradle.kts"
        
        storeFile=$(grep 'storeFile = file("[^"]*"' "$buildScript" | sed 's/.*storeFile = file("\([^"]*\)".*/\1/')
        storeFile="$workDir/app/$storeFile"
        
        storePassword=$(grep 'storePassword = "[^"]*"' "$buildScript" | sed 's/.*storePassword = "\([^"]*\)".*/\1/')
        
        keyAlias=$(grep 'keyAlias = "[^"]*"' "$buildScript" | sed 's/.*keyAlias = "\([^"]*\)".*/\1/')
        
        keyPassword=$(grep 'keyPassword = "[^"]*"' "$buildScript" | sed 's/.*keyPassword = "\([^"]*\)".*/\1/')
    }
    info "storeFile: $storeFile"
}

readPackageName() {
    [ -z "$packageName" ] &&
    packageName=$(grep 'applicationId = "[^"]*"' "$workDir"/app/build.gradle.kts | sed 's/.*applicationId = "\([^"]*\)".*/\1/')
    info "packageName   = $packageName"
}

readVersionName() {
    [ -z "$versionName" ] &&
    versionName=$(grep 'versionName = "[^"]*"' "$workDir"/app/build.gradle.kts | sed 's/.*versionName = "\([^"]*\)".*/\1/')
    info "versionName   = $versionName"
}

readCompileSdkVersion() {
    [ -z "$compileSdkVersion" ] &&
    compileSdkVersion=$(grep 'compileSdkVersion([0-9]*)' "$workDir"/app/build.gradle.kts | sed 's/.*compileSdkVersion(\([0-9]*\)).*/\1/')
    info "compileSdkVersion : $compileSdkVersion"
}

readBuildToolsInfo() {
    checkANDROID_HOME

    [ -z "$buildToolsVersion" ] &&
    buildToolsVersion=$(grep 'buildToolsVersion("[^"]*")' "$workDir"/app/build.gradle.kts | sed 's/.*buildToolsVersion("\([^"]*\)").*/\1/')
    info "buildToolsVersion : $buildToolsVersion"
    
    [ -z "$buildToolsDir" ] &&
    buildToolsDir=$ANDROID_HOME/build-tools/$buildToolsVersion
    info "buildToolsDir     : $buildToolsDir"
}

checkANDROID_HOME() {
    [ -z "$ANDROID_HOME" ] && error "ANDROID_HOME not set!"
    [ -d "$ANDROID_HOME" ] && {
        success "ANDROID_HOME=$ANDROID_HOME"
        return $?
    }
    info "ANDROID_HOME=$ANDROID_HOME"
    error "ANDROID_HOME must be a directory!"
}

checkJAVA_HOME() {
    [ -z "$JAVA_HOME" ] && error "JAVA_HOME not set!"
    [ -d "$JAVA_HOME" ] && {
        success "JAVA_HOME=$JAVA_HOME"
        return $?
    }
    info "JAVA_HOME=$JAVA_HOME"
    error "JAVA_HOME must be a directory!"
}

#检查是否是文件
#$1是文件路径
checkIsFile() {
    [ -f "$1" ] || error "$1 is not file"
}

#检查是否具有可执行权限
#$1是文件路径
checkExecutable() {
    [ -x "$1" ] && return 0
        
    warn "$1 can not be excuted!"
    info "$(ls -l "$1")"
    info "we try to change the mode of $1"
    $sudo chmod u+x "$1" || error "change the mode of $1 failed."
}

getjava() {
    java=$(command -v java)
    [ -z "$java" ] && {
        checkJAVA_HOME
        java="$JAVA_HOME/bin/java"
    }
    
    checkIsFile "$java"
    checkExecutable "$java"
     
    success "java : $java"
    "$java" -version &> tmp
    while read -r line
    do
        success "$line"
    done < tmp
    rm tmp
}

getkeytool() {
    keytool=$(command -v keytool)
    [ -z "$keytool" ] && {
        checkJAVA_HOME
        keytool="$JAVA_HOME/bin/keytool"
    }
    
    checkIsFile "$keytool" 
    checkExecutable "$keytool"
    
    success "keytool : $keytool"
}

getjarsigner() {
    jarsigner=$(command -v jarsigner)
    [ -z "$jarsigner" ] && {
        checkJAVA_HOME
        jarsigner="$JAVA_HOME/bin/jarsigner"
    }
    
    checkIsFile "$jarsigner" 
    checkExecutable "$jarsigner"
     
    success "jarsigner : $jarsigner"
}

getsdkmanager() {
    sdkmanager=$(command -v sdkmanager)
    [ -z "$sdkmanager" ] && {
        checkANDROID_HOME
        sdkmanager="$ANDROID_HOME/tools/bin/sdkmanager"
    }
    
    checkIsFile "$sdkmanager"
    checkExecutable "$sdkmanager"
     
    success "sdkmanager : $sdkmanager"
}

getadb() {
    adb=$(command -v adb)
    [ -z "$adb" ] && {
        checkANDROID_HOME
        adb="$ANDROID_HOME/platform-tools/adb"
    }
    
    checkIsFile "$adb" 
    checkExecutable "$adb"
     
    success "adb      : $adb"
}

getaapt() {
    aapt=$(command -v aapt)
    [ -z "$aapt" ] && {
        readBuildToolsInfo
        aapt="$buildToolsDir/aapt"
    }
    
    checkIsFile "$aapt"
    checkExecutable "$aapt"
    
    success "aapt     : $aapt"
}

getapksigner() {
    apksigner=$(command -v apksigner)
    [ -z "$apksigner" ] && {
        readBuildToolsInfo
        apksigner="$buildToolsDir/apksigner"
    }
    
    checkIsFile "$apksigner"
    checkExecutable "$apksigner"
    
    success "apksigner : $apksigner"
}

getzipalign() {
    zipalign=$(command -v zipalign)
    [ -z "$zipalign" ] && {
        readBuildToolsInfo
        zipalign="$buildToolsDir/zipalign"
    }
    
    checkIsFile "$zipalign"
    checkExecutable "$zipalign"
    
    success "zipalign : $zipalign"
}

install7zipIfNeeded() {
    p7z=$(command -v 7za)
    
    [ -z "$p7z" ] && p7z=$(command -v 7z)
    
    [ -z "$p7z" ] && installPackage p7zip p7zip-full p7zip p7zip p7zip p7zip && p7z=$(command -v 7za)
    
    [ -z "$p7z" ] && p7z=$(command -v 7z)
    
    [ -z "$p7z" ] && error "can't find 7za."
    
    success "7z : $p7z"
}

#$1是HomeBrew软件包的名称
#$2是apt-get软件包的名称
#$3是dnf软件包的名称
#$4是yum软件包的名称
#$5是zypper软件包的名称
#$6是pacman软件包的名称
installPackage() {
    info "installPackage()"

    if [ "$osType" == "Darwin" ] ; then
        installOrUpdateHomeBrew &&
        info "installing $1 ..." &&
        brew install "$1" &&
        success "installed $1!"
    elif [ "$osType" == "Linux" ] ; then
        command -v apt-get &> /dev/null && {
            info "installing $2 ..." &&
            $sudo apt-get -y update &&
            $sudo apt-get -y install "$2" &&
            success "installed $2!"
            return $?
        }
        command -v dnf &> /dev/null && {
            info "installing $3 ..." &&
            $sudo dnf -y update &&
            $sudo dnf -y install "$3" &&
            success "installed $3!"
            return $?
        }
        command -v yum &> /dev/null && {
            info "installing $4 ..." &&
            $sudo yum -y update &&
            $sudo yum -y install "$4" &&
            success "installed $4!"
            return $?
        }
        command -v zypper &> /dev/null && {
            info "installing $5 ..." &&
            $sudo zypper update -y &&
            $sudo zypper install -y "$5" &&
            success "installed $5!"
            return $?
        }
        command -v pacman &> /dev/null && {
            info "installing $6 ..." &&
            $sudo pacman -Syyuu --noconfirm &&
            $sudo pacman -S     --noconfirm "$6" &&
            success "installed $6!"
            return $?
        }
    fi

    error "We don't recognize your os!"
}

#安装或者更新HomeBrew
installOrUpdateHomeBrew() {
    command -v brew &> /dev/null && (brew update; return $?)
    echo -e "\n" | /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
}

installCurlIfNeeded() {
    info "installCurlIfNeeded()"
    command -v curl &> /dev/null ||
    installPackage curl curl curl curl curl curl
}

#只安装WebP的工具，使用里面的cwebp
installLibWebpIfNeeded() {
    command -v cwebp &> /dev/null ||
    installPackage webp webp libwebp-tools libwebp-tools libwebp-tools libwebp
}

#安装或者更新Android SDK
updateAndroidSDK() {
    getsdkmanager &&
    readCompileSdkVersion &&
    readBuildToolsInfo &&
    info "updating android sdk..." &&
    echo y | "$sdkmanager" "platforms;android-${compileSdkVersion}" && local platforms=true &&
    echo y | "$sdkmanager" "platform-tools" && local platformTools=true &&
    echo y | "$sdkmanager" "build-tools;${buildToolsVersion}" && local buildTools=true
    echo y | "$sdkmanager" "ndk-bundle" && local ndkBundle=true
    
    if [ -z "$platforms" ] ; then
        errorOnly "platforms;android-${compileSdkVersion}"
    else
        success "platforms;android-${compileSdkVersion}"
    fi
    
    if [ -z "$platformTools" ] ; then
        errorOnly "platform-tools"
    else
        success "platform-tools"
    fi

    if [ -z "$buildTools" ] ; then
        errorOnly "build-tools;${buildToolsVersion}"
    else
        success "build-tools;${buildToolsVersion}"
    fi

    if [ -z "$ndkBundle" ] ; then
        errorOnly "ndk-bundle"
    else
        success "ndk-bundle"
    fi
}

#执行单元测试
unitTest() {
    readPackageName &&
    getadb &&
    info "run unit testing..." &&
    "$adb" shell am instrument -w "$packageName.test/android.test.InstrumentationTestRunner"
}

#执行Monkey测试
monkeyTest() {
    readPackageName &&
    getadb &&
    info "run monkey testing..." &&
    "$adb" shell monkey -p "$packageName" -vvv 20000
}

#执行SonarQube代码扫描
runSonarScanner() {
    local sonarScannerConfigFile="$workDir/sonar-project.properties"
    [ -f "$sonarScannerConfigFile" ] || error "$sonarScannerConfigFile not exsit."
    
    info "run sonar scanner..."
    local currentDateTime; currentDateTime=$(date +%Y%m%d_%H%M%S)
    info "currentDateTime : $currentDateTime"
    
    sedCompatible "s/[0-9]\{8\}/${currentDateTime}/g" "$sonarScannerConfigFile"
    
    "$workDir/gradlew" lint && sonar-runner
}

#$1是png或者jpg
convertToWebPInternal() {
    local imageFiles; imageFiles=$(find . -name "*.$1")
    for imageFile in $imageFiles
    do
        if echo "$imageFile" | grep "\.9.png" &> /dev/null; then
            info "$imageFiles is 9 png, so not convert"
        else
            local name; name=$(basename "$imageFile")
            if [ "$name" = "ic_launcher.png" ] ; then
                continue
            else
                #cwebp $imageFile -o `dirname $imageFile`/`basename $imageFile .png`.webp &&
                #rm $imageFile
                cwebp "$imageFile" -o "$imageFile"
            fi
        fi
    done
}

#转换图片为WebP
convertToWebP() {
    installLibWebpIfNeeded && 
    convertToWebPInternal "png" &&
    convertToWebPInternal "jpg"
}

#安装apk
#$1是apk路径
installApk() {
    checkValidApk "$1" &&
    getadb &&
    info "installing $1 ..." &&
    "$adb" install -r -t "$1"
}

#卸载当前设备上的应用
uninstallApk() {
    readPackageName &&
    getadb &&
    info "uninstalling package $packageName ..." &&
    "$adb" uninstall "$packageName"
}

#显示KeyStore中的指定KeyAlias的MD5
showCertificateFingerprints() {
    readKeyStoreInfo &&
    getkeytool &&
    "$keytool" -list -v -keystore "$storeFile" -storepass "$storePassword" -alias "$keyAlias"
}

# 删除apk中的签名信息
# $1 是apk的路径
removeV1SignInfo() {
    checkValidApk "$1"
    getaapt
    "$aapt" r "$1" META-INF/CERT.SF
    "$aapt" r "$1" META-INF/CERT.RSA
    "$aapt" r "$1" META-INF/MANIFEST.MF
}

# 给Apk进行V1签名
# $1 是apk文件的路径
v1Sign() {
    removeV1SignInfo "$1"
    getjarsigner
    readKeyStoreInfo
    v1SignResult="$(appendFileName "$1" v1signed)"
    "$jarsigner" -verbose -keystore "$storeFile" -storepass "$storePassword" -digestalg SHA1 -sigalg MD5withRSA -sigfile CERT -signedjar "$v1SignResult" "$1" "$keyAlias" ||
    error "v1 sign failed."
}

# 给Apk进行V2签名
# $1 是apk文件的路径
v2Sign() {
    info "v2Sign() inputApk=$1"
    checkValidApk "$1"
    getapksigner
    readKeyStoreInfo
    v2SignResult="$(appendFileName "$1" v2signed)"
    "$apksigner" sign --ks "$storeFile" --ks-pass pass:"$storePassword" --ks-key-alias "$keyAlias" --key-pass pass:"$storePassword" --out "$v2SignResult" "$1" ||
    error "v2 sign failed!"
}

#对v2签名进行校验
# $1 是apk文件的路径
v2SignVerify() {
    checkValidApk "$1"
    getapksigner
    "$apksigner" verify --verbose "$1" ||
    error "v2SignVerify failed."
}

# 对Apk进行字节对齐优化
# $1 是apk文件的路径
alignApk() {
    checkValidApk "$1"
    getzipalign
    alignApkResult="$(appendFileName "$1" aligned)"
    "$zipalign" -v -f 4 "$1" "$alignApkResult" ||
    error "alignApk failed."
}

#xxx.apk 接上zipaligned变为xxx_zipaligned.apk
#$1为原来的路径
#$2为要追加的字符串
appendFileName() {
    echo "$(dirname "$1")/$(basename "$1" .apk)_$2.apk"
}

#显示Apk的版本名称
# $1 是apk文件的路径
showApkVersion() {
    checkValidApk "$1"
    getaapt
    "$aapt" dump badging "$1" | grep "version"
}

# 监测是否是一个Apk文件
# $1 是apk文件的路径
checkValidApk() {
    [ -z "$1" ] && error "checkValidApk: please apply a apk file path ~"
    [ -f "$1" ] || error "checkValidApk: $1 is not exist ~"
    unzip -t "$1" &> /dev/null ||
    error "checkValidApk: $1 is not a valid apk file ~"
}

#打开Genymotion模拟器
openGenymotion() {
    command -v player &> /dev/null ||
    error "can't find Genymotion player."
    player --vm-name "Google Nexus 5 - 4.4.4 - API 19 - 1080x1920" &
}

# 替换local.properties中的Android SDK路径
setAndroidSDKHomeInLocalProperties() {
    sedCompatible "s#sdk\.dir=.*#sdk.dir=${ANDROID_HOME}#g" "$workDir/local.properties"
}

# 替换build.gradle.kts里面的版本号（versionCode）
# $1是版本号，版本号使用十位的Unix时间戳，它精确到秒，而且它不会超过Java中的int类型的最大范围（2147483647），示例：1516856238
setVersionCodeInBuildGradle() {
    sedCompatible "s/versionCode = [0-9]\{1,10\}/versionCode = $1/g" "$workDir/app/build.gradle.kts"
}

# 替换build.gradle.kts里面的包号（applicationId）
setPackageNameInBuildGradle() {
    sedCompatible "s/applicationId = \".*\"/applicationId = \"${packageName}\"/g" "$workDir/app/build.gradle.kts"
}

# 修改AndroidManifest.xml里面的android:debuggable开关
# $1 为true | false字符串
setDebuggable() {
    local origin=true
    local toggle=false
    if [ "$1" == "true" ] ; then
        origin=false
        toggle=true
    else
        origin=true
        toggle=false
    fi
    
    sedCompatible "s/android:debuggable=\"${origin}\"/android:debuggable=\"${toggle}\"/g" "$workDir/app/src/main/AndroidManifest.xml"
}

#使用curl下载
#$1是下载的URL
#$2是目的文件名称，注意：不是文件夹，全部存放在$workDir/tools目录中
downloadWithCurl() {
    info "downloadWithCurl()"

    installCurlIfNeeded &&
    mkdir -p "$workDir/tools" &&
    info "downloading $1" &&
    curl -L -o "$workDir/tools/$2" "$1" &&
    success "downloaded $1 to $workDir/tools directory."
}

downloadWalle() {
    local url="https://github.com/Meituan-Dianping/walle/releases/download/v1.1.6/walle-cli-all.jar"
    local output="walle-cli.jar"
    downloadWithCurl $url $output
}

downloadWalleIfNeeded() {
    info "downloadWalleIfNeeded()"
    walleCliJar="$workDir/tools/walle-cli.jar"
    if [ -f "$walleCliJar" ] ; then
        unzip -t "$walleCliJar" &> /dev/null && return 0
        rm -f "$walleCliJar" && downloadWalle
    else
        downloadWalle
    fi
}

checkChannelsConfig() {
    [ -f "channels-config.txt" ] || error "channels-config.txt not exsit."
}

# $1是apk的文件路径
genChannels() {
    downloadWalleIfNeeded &&
    getjava && 
    mkdir -p "channels-$2" && 
    "$java" -jar "$walleCliJar" batch -f "channels-config.txt" "$1" "channels-$2"
}


#下载360加固保
#$1是系统标志：mac|win
#$2是系统的位数
downloadJiagu() {
    local baseUrl="http://down.360safe.com/360Jiagu/360jiagubao_"
    if [ "$1" == "mac" ] ; then
        downloadWithCurl "${baseUrl}mac.zip" "360jiagubao_mac.zip"
    else
        downloadWithCurl "${baseUrl}windows_$2.zip" "360jiagub_windows_$2.zip"
    fi
}

downloadJiaguIfNeeded() {
    local jiaguZip="$workDir/tools/360jiagubao_mac.zip"
    if [ -f "$jiaguZip" ] ; then
        unzip -t "$jiaguZip" &> /dev/null && return 0 
        rm -f "$jiaguZip" && downloadJiagu mac
    else
        downloadJiagu mac
    fi
}

read360mobileAccount() {
    _360ConfigFile="$HOME/.360mobile.properties"
    
    [ -f "$_360ConfigFile" ] || {
        cat > "$_360ConfigFile" << EOF
username=
password=
EOF
        error "please config $_360ConfigFile first."
    }
    
    _360UserName=$(grep "username=" "$_360ConfigFile" | sed 's/^username=\(.*\)/\1/')
    _360Password=$(grep "password=" "$_360ConfigFile" | sed 's/^password=\(.*\)/\1/')

    [ -z "$_360UserName" ] && error "please config $_360ConfigFile first."
    [ -z "$_360Password" ] && error "please config $_360ConfigFile first."
    info "360mobile =>"
    info "    username  = $_360UserName"
}

prepareJiaguCommand() {
    local toolsDir="$workDir/tools"
    [ -d "$toolsDir" ] || mkdir -p "$toolsDir"
    
    if [ "$osType" = "Darwin" ] || [ "$osType" = "Linux" ] ; then
        #因为360加固保里包含中文，使用7z才能解压不出错
        local unzipDir="$toolsDir/360jiagubao_mac"
        jiaguJar="$unzipDir/jiagu/jiagu.jar"
        downloadJiaguIfNeeded &&
        install7zipIfNeeded &&
        "$p7z" x "$toolsDir/360jiagubao_mac.zip" -y -o"$unzipDir"
        chmod -R a+x "$unzipDir/jiagu/java"
    else
        "$java" -version &> tmp
        local bit; bit=$(grep "Java HotSpot" tmp | sed 's/^.*Java HotSpot(TM) \([0-9][0-9]\)-Bit.*/\1/')
        rm tmp
        local unzipDir=$toolsDir/360jiagubao_windows_${bit}
        apksigner=${apksigner}.bat
    fi
    
    getjava
    jiagu="$java -jar $jiaguJar"
    
    #更新程序到最新
    $jiagu -update
}

jiaguInternal() {
    #使用360账户登录，首次用脚本登录会失败，它要求在GUI下用图片验证码进行验证，但是code却是0
    $jiagu -login "$_360UserName" "$_360Password"
    
    #导入签名信息
    $jiagu -importsign "$storeFile" "$storePassword" "$keyAlias" "$keyPassword" || error "your keyStore is not right!"
    
    local apkDir; apkDir=$(dirname "$1")
    info "jiaguInternal() apkDir = $apkDir"

    #加固，并进行v1签名
    $jiagu -jiagu "$1" "$apkDir" -autosign || error "jiagu failed!"
    
    jiaguResult=$(find "$apkDir" -name "*_jiagu_sign.apk" | head -n 1)
}

jiagu() {
    prepareJiaguCommand
    readKeyStoreInfo
    jiaguInternal "$@"
    [ -f "$jiaguResult" ] || {
        errorOnly "login 360 failed. there are posible reasons:"
        errorOnly "1、360's username or password is not correct!"
        errorOnly "2、there is no network!"
        errorOnly "3、you are first login, must login from GUI"
        errorOnly "we start GUI, you can login from GUI, login successed , then close the GUI, we will retry."
        errorOnly "errorCode: https://bbs.360.cn/thread-15488914-1-1.html"
        $jiagu
        jiaguInternal "$@"
    }
}

downloadAndResGuard() {
    local url="https://raw.githubusercontent.com/leleliu008/auto/master/android-project/AndResGuard-cli-1.2.16.jar"
    downloadWithCurl "$url" "AndResGuard-cli.jar"
}

downloadAndResGuardIfNeeded() {
    info "downloadAndResGuardIfNeeded()"
    local andResGuardCliJar="$workDir/tools/AndResGuard-cli.jar"
    if [ -f "$andResGuardCliJar" ] ; then
        unzip -t "$andResGuardCliJar" &> /dev/null && return 0
        rm "$andResGuardCliJar" && downloadAndResGuard
    else
        downloadAndResGuard
    fi
}

checkAndResGuardConfig() {
    [ -f "$workDir/AndResGuard-config.xml" ] && return 0
    
    [ -f "$workDir/tools/AndResGuard-config.xml" ] &&
    error "$workDir/AndResGuard-config.xml not exsit. you can copy $workDir/tools/AndResGuard-config.xml, then modify from it. see details: https://github.com/shwenzhang/AndResGuard/blob/master/doc/how_to_work.md#how-to-write-configxml-file"
    
    readPackageName

    local url="https://raw.githubusercontent.com/leleliu008/auto/master/android-project/AndResGuard-config.xml" 
    downloadWithCurl "$url" "AndResGuard-config.xml" && 
    sedCompatible "s@com.fpliu.newton@${packageName}@g" "$workDir/tools/AndResGuard-config.xml" && 
    error "$workDir/AndResGuard-config.xml not exsit. you can copy $workDir/tools/AndResGuard-config.xml, then modify from it. see details: https://github.com/shwenzhang/AndResGuard/blob/master/doc/how_to_work.md#how-to-write-configxml-file"

    error "$workDir/AndResGuard-config.xml not exsit. you can download a copy from $url, then modify from it to suit yours. see details: https://github.com/shwenzhang/AndResGuard/blob/master/doc/how_to_work.md#how-to-write-configxml-file"
}

# 使用https://github.com/shwenzhang/AndResGuard进行资源混淆
# $1是apk的文件路径
resguard() {
    local inputApk="$1"
    local prefix; prefix=$(basename "$inputApk" .apk)
    local inputDir; inputDir=$(dirname "$inputApk")
    local outputDir="$inputDir/resguard"
    resguardResult="$inputDir/${prefix}_resguard.apk"

    getjava &&
    getzipalign &&
    readKeyStoreInfo &&
    install7zipIfNeeded &&
    downloadAndResGuardIfNeeded &&
    checkAndResGuardConfig && 
    "$java" -jar "$workDir/tools/AndResGuard-cli.jar" "$inputApk" \
         -config "$workDir/AndResGuard-config.xml" \
         -out "$outputDir" \
         -7zip "$p7z" \
         -zipalign "$zipalign" \
         -signatureType v2 \
         -signature "$storeFile" "$storePassword" "$keyPassword" "$keyAlias" &&
    cp "$outputDir/${prefix}_7zip_aligned_signed.apk" "$resguardResult"
    [ -f "$resguardResult" ] || error "resguard failed."
}

#把APK中的图片全部转换为webp
#$1为要处理的apk的路径
#结果为转换后的apk路径
convertToWebPInApk() {
    local apkDir; apkDir="$(dirname "$1")"
    local unzipDir; unzipDir="$apkDir/$(date +%Y%m%d%H%M%S)"
    local prefix; prefix="$(basename "$1" .apk)"
    local webpdApk="${prefix}_webp.apk"
    
    info "convertToWebPInApk()"
    info "pwd         : $(pwd)"
    info "inputApk    : $1"
    info "apkDir      : $apkDir"
    info "prefix      : $prefix"
    info "webpdApk    : $webpdApk"
    
    unzip "$1" -d "$unzipDir" && 
    cd "$unzipDir" && 
    rm -rf META-INF && 
    rm -rf res/layout-watch-v20 && 
    rm -rf res/drawable-watch-v20 && 
    rm -rf res/drawable-ldrtl-mdpi-v17 && 
    rm -rf res/drawable-ldrtl-hdpi-v17 && 
    rm -rf res/drawable-ldrtl-xhdpi-v17 &&
    rm -rf res/drawable-ldrtl-xxhdpi-v17 && 
    rm -rf res/drawable-ldrtl-xxxhdpi-v17 &&
    convertToWebP &&
    install7zipIfNeeded &&
    "$p7z" a -tzip -mx9 "$webpdApk" . &&
    mv "$webpdApk" "$apkDir" &&
    cd "$workDir" &&
    v1Sign "$apkDir/$webpdApk" &&
    convertToWebPInApkResult="$v1SignResult"
}

#使用redex优化apk
#$1为要处理的apk的路径
#结果为转换后的apk路径
redexApk() {
    redexApkResult=$(appendFileName "$1" redexed)
    redex "$1" -o "$redexApkResult"
    [ -f "$redexApkResult" ]|| error "redexApk failed."
}

# 执行编译，命令如下：
#./tool.sh build debug --resguard --jiagu --channel
#    $0      $1    $2      $3        $4      $5
#shift 1之后
#build debug --resguard --jiagu --channel
#  $0    $1       $2       $3       $4
# $1取值为 debug | release | develop | demo
# $2取值为--resguard，表示要混淆资源
# $3取值为--jiagu，表示要进行加固
# $4取值为--channel，表示要构建渠道包
runBuild() {
    #左移一项，跳过./tool.sh
    shift 1
    
    #校验第二个参数是不是预想的那4个
    case $1 in
        "debug")
            environment="debug"
            ;;
        "release")
            environment="release"
            ;;
        "develop")
            environment="develop"
            ;;
        "demo")
            environment="demo"
            ;;
        *)
            error "environment must one of debug/release/develop/demo"
    esac
    
    while true
    do
        [ $# -eq 1 ] && break
        shift 1
        if [ "$1" = "--webp" ] ; then
            isWebp=true
        elif [ "$1" = "--resguard" ] ; then
            isResGuard=true
        elif [ "$1" = "--redex" ] ; then
            isReDex=true
        elif [ "$1" = "--jiagu" ] ; then
            isJiaGu=true
            read360mobileAccount
        elif [ "$1" = "--channel" ] ; then
            isGenChannels=true
            checkChannelsConfig
        fi
    done
    
    [ -z "$isWebp" ]        && isWebp=false
    [ -z "$isResGuard" ]    && isResGuard=false
    [ -z "$isReDex" ]       && isReDex=false
    [ -z "$isJiaGu" ]       && isJiaGu=false
    [ -z "$isGenChannels" ] && isGenChannels=false
    [ -z "$appName" ]       && appName="$(basename "$workDir")"
    
    info "environment   = $environment"
    info "isWebp        = $isWebp"
    info "isResGuard    = $isResGuard"
    info "isReDex       = $isReDex"
    info "isJiaGu       = $isJiaGu"
    info "isGenChannels = $isGenChannels"
    info "appName       = $appName"
    
    readVersionName
     
    local ts; ts=$(date +%Y%m%d_%H%M%S)    
    local outputFile; outputFile="${appName}_${versionName}_${ts}_$environment.apk"
    info "outputFile    = $outputFile"
    
    setAndroidSDKHomeInLocalProperties

    #修改版本号（版本号使用十位的Unix时间戳，它精确到秒，而且它不会超过Java中的int类型的最大范围（2147483647），示例：1516856238）
    setVersionCodeInBuildGradle "$(date +%s)"

    #删除掉构建目录
    rm -rf "$(find . -name "build")"
    #清除掉上次编译的其他临时数据
    "$workDir/gradlew" clean

    if [ "$environment" = "release" ] ; then
        internalMode1="release"
        internalMode2="Release"
        setDebuggable false
    else
        internalMode1="debug"
        internalMode2="Debug"
        setDebuggable true
    fi
   
    "$workDir/gradlew" assemble$internalMode2 || error "build failed."

    local apkDir=$workDir/app/build/outputs/apk/$internalMode1
    local currentApkFile=$apkDir/app-${internalMode1}.apk
    
    [ "$isWebp" = "true" ] &&
    convertToWebPInApk "$currentApkFile" &&
    currentApkFile="$convertToWebPInApkResult"
    
    [ "$isReDex" = "true" ] &&
    redexApk "$currentApkFile" &&
    currentApkFile="$redexApkResult"
    
    [ "$isResGuard" = "true" ] && 
    resguard "$currentApkFile" &&
    currentApkFile="$resguardResult"
    
    [ "$isJiaGu" = "true" ] && {
        jiagu "$currentApkFile" &&
        currentApkFile="$jiaguResult"
        
        #字节对齐优化
        alignApk "$currentApkFile" &&
        currentApkFile="$alignApkResult"
        
        #进行v2签名
        v2Sign "$currentApkFile" &&
        currentApkFile="$v2SignResult"
        
        #对v2签名进行校验
        v2SignVerify "$currentApkFile"
    }
    
    #复制最终的apk文件，并进行渠道包的构建
    cp "$currentApkFile" "$outputFile" && 
    [ "$isGenChannels" = "true" ] && 
    genChannels "$outputFile" "$ts" &&
    success "All done."
}

doctor() {
    #check JDK
    getjava
    getkeytool
    getjarsigner

    #check Android SDK
    getsdkmanager
    getadb
    getaapt
    getzipalign
}

# 显示帮助
showHelp() {
	cat <<EOF
Usage:

./tool.sh <command> [sub-command] [option]...

./tool.sh test unit           run unit test

./tool.sh test monkey         run monkey test

./tool.sh sonar               run sonar scanner

./tool.sh show cert           show your keystore's content

./tool.sh show version        print the apk's versionCode and versionName

./tool.sh install <APKFILE>   install the apk to the connected device

./tool.sh uninstall           uninstall my package form the connected device

./tool.sh resguard <APKFILE>  resguard apk

./tool.sh sign <APKFILE>      sign the apk

./tool.sh align <APKFILE>     align the apk

./tool.sh signAlign <APKFILE> sign and align the apk

./tool.sh convertToWebP       convert res/xx/*.png res/xx/*.jpg to webp Format, be carefull, backup your project before running this command.

./tool.sh update android-sdk

./tool.sh build <environment> [option]...
    environment: 
        must be one of debug/release/develop/demo
    option: 
        --webp       convert images to webp, default false
        --resguard   guard res, default false
        --redex      rebuild dex to optimize, default false
        --jiagu      jiagu with 360jiagubao, default false
        --channel    build channels, default false
    examples: 
        ./tool.sh build debug
        ./tool.sh build release --webp --resguard --jiagu --channel
EOF
    exit 1
}

main() {
    [ -z "$1" ] && showHelp
    
    initValues
     
    case $1 in
        "doctor")
            doctor
            ;;
        "test")
            if [ "$2" = 'unit' ] ; then
		        unitTest
	        elif [ "$2" = 'monkey' ] ; then
		        monkeyTest
            else
                showHelp
	        fi
            ;;
        "sonar")
	        runSonarScanner
            ;;
        "convertToWebP")
	        convertToWebP
            ;;
        "show")
            if [ "$2" = 'cert' ] ; then
                showCertificateFingerprints
	        elif [ "$2" = 'version' ] ; then
	            showApkVersion "$3"
	        else
	            showHelp
	        fi
            ;;
        "install")
	        installApk "$2"
            ;;
        "uninstall")
	        uninstallApk "$2"
            ;;
        "resguard")
            resguard "$2"
            ;;
        "sign")
	        signApk "$2"
            ;;
        "align")
	        alignApk "$2"
            ;;
        "signAlign")
	        signApk "$2" && alignApk "$2"
            ;;
        "genymotion")
	        openGenymotion
            ;;
        "build")
            if [ -z "$2" ] ; then
                showHelp
            else
		        runBuild "$@"
            fi
            ;;
        "update")
            if [ "$2" = 'android-sdk' ] ; then
                updateAndroidSDK
            else
                showHelp
            fi
            ;;
        *)
            showHelp
    esac
}

main "$@"
