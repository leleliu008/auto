#!/bin/bash

#--------------------- these config can change------------
_360UserName="hyzb_it"
_360Password="hyzb@2017"
appName=dsa_for_android

#---------------------------------------------------------

Color_Red='\033[0;31m'          # Red
Color_Green='\033[0;32m'        # Green
Color_Yellow='\033[0;33m'       # Yellow
Color_Blue='\033[0;34m'         # Blue
Color_Purple='\033[0;35m'       # Purple
Color_Cyan='\033[0;36m'         # Cyan
Color_Off='\033[0m'             # Text Reset

function msg() {
    printf "%b\n" "$1"
}

function success() {
    msg "${Color_Green}[✔]${Color_Off} $1$2"
}

function info() {
    msg "${Color_Purple}[❉]${Color_Off} $1$2"
}

function warn() {
    msg "${Color_Yellow}[⌘]${Color_Off} $1$2"
}

function error() {
    msg "${Color_Red}[✘]${Color_Off} $1$2"
}

function initValues() {
    [ -z "$workDir" ] && \
    osType=$(uname -s)
    info "osType  : $osType"
    
    [ -z "$workDir" ] && \
    workDir=$(cd $(dirname $0); pwd)
    info "workDir : $workDir"
    
    [ -z "$packageName" ] && \
    packageName=`grep 'applicationId = "[^"]*"' $workDir/app/build.gradle.kts | sed 's/.*applicationId = "\([^"]*\)".*/\1/'`
    info "packageName : $packageName"
    
    [ -z "$versionName" ] && \
    versionName=`grep 'versionName = "[^"]*"' $workDir/app/build.gradle.kts | sed 's/.*versionName = "\([^"]*\)".*/\1/'`
    info "versionName : $versionName"
    
    [ -z "$buildToolsVersion" ] && \
    buildToolsVersion=`grep 'buildToolsVersion("[^"]*")' $workDir/app/build.gradle.kts | sed 's/.*buildToolsVersion("\([^"]*\)").*/\1/'`
    info "buildToolsVersion : $buildToolsVersion"
    
    [ -z "$buildToolsDir" ] && \
    buildToolsDir=$ANDROID_HOME/build-tools/$buildToolsVersion
    info "buildToolsDir     : $buildToolsDir"

    [ -z "$compileSdkVersion" ] && \
    compileSdkVersion=`grep 'compileSdkVersion([0-9]*)' $workDir/app/build.gradle.kts | sed 's/.*compileSdkVersion(\([0-9]*\)).*/\1/'`
    info "compileSdkVersion : $compileSdkVersion"
}

function readKeyStoreInfo() {
    [ -z "$storeFile" ] && {
        storeFile=`grep 'storeFile = file("[^"]*"' $workDir/app/build.gradle.kts | sed 's/.*storeFile = file("\([^"]*\)".*/\1/'`
        storeFile=$workDir/app/$storeFile
        
        storePassword=`grep 'storePassword = "[^"]*"' $workDir/app/build.gradle.kts | sed 's/.*storePassword = "\([^"]*\)".*/\1/'`
        
        keyAlias=`grep 'keyAlias = "[^"]*"' $workDir/app/build.gradle.kts | sed 's/.*keyAlias = "\([^"]*\)".*/\1/'`
        
        keyPassword=`grep 'keyPassword = "[^"]*"' $workDir/app/build.gradle.kts | sed 's/.*keyPassword = "\([^"]*\)".*/\1/'`
    }
    
    info "-----------------------------------"
    info "storeFile    : $storeFile"
    info "keyAlias     : $keyAlias"
    info "-----------------------------------"
}

#更新Android SDK
function updateAndroidSDK() {
    local sdkmanager=$(command -v sdkmanager)
    [ -z "$sdkmanager" ] && sdkmanager="${ANDROID_HOME}/tools/bin/sdkmanager"
    if [ -f "$sdkmanager" ] ; then
        info "updating android sdk..."
        echo y | "$sdkmanager" "platforms;android-${compileSdkVersion}" 
        echo y | "$sdkmanager" "platform-tools" 
        echo y | "$sdkmanager" "build-tools;${buildToolsVersion}" 
        echo y | "$sdkmanager" "ndk-bundle" 
    else
        echo y | android update sdk --no-ui --all --filter android-${compileSdkVersion},platform-tools,build-tools-${buildToolsVersion},extra-android-m2repository
    fi
}

#执行单元测试
function testWithUnit() {
    info "run unit testing..."
    adb shell am instrument -w ${packageName}.test/android.test.InstrumentationTestRunner
}

#执行Monkey测试
function testWithMonkey() {
    info "run monkey testing..."
    adb shell monkey -p ${packageName} -vvv 20000
}

#执行SonarQube代码扫描
function runSonarScanner() {
    info "run sonar scanner..."
    currentDateTime=`date +%Y%m%d_%H%M%S`
    info "currentDateTime=$currentDateTime"

    if [ "$osType" == 'Darwin' ] ; then
    	sed -i ""  "s#[0-9]\{8\}#${currentDateTime}#g" $workDir/sonar-project.properties
    else
    	sed -i "s#[0-9]\{8\}#${currentDateTime}#g" $workDir/sonar-project.properties
    fi

    $workDir/gradlew lint && sonar-runner
}

#转换图片为WebP
function convertToWebP() {
    command -v cwebp &> /dev/null
    if [ $? -eq 0 ] ; then
            local imageFiles=`find . -name "*.png"`
            for imageFile in $imageFiles
            do
                echo $imageFile | grep "\.9.png" &> /dev/null
                if [ $? -eq 0 ] ; then
                    info "$imageFiles is 9 png, so not convert"
                else
                    local name=`basename $imageFile`
                    if [ $name = "ic_launcher.png" ] ; then
                        continue
                    else
                        #cwebp $imageFile -o `dirname $imageFile`/`basename $imageFile .png`.webp && \
                        #rm $imageFile
                        cwebp $imageFile -o $imageFile
                    fi
                fi
            done
    else
        info "cwebp is not installed! I'm trying to install it!"
        command -v brew &> /dev/null
        if [ $? -eq 0 ] ; then
            brew install webp
        else
            warn "cwebp is not installed! Cause brew is not installed!"
        fi
    fi
}

#安装编译好的应用
function installApk() {
    info "installing apk ..."
    adb install -r -t *.apk
}

#卸载当前设备上的应用
function uninstallApk() {
    info "uninstalling package $packageName ..."
    adb uninstall $packageName
}

#显示KeyStore中的指定KeyAlias的MD5
function showCertificateFingerprints() {
    readKeyStoreInfo && \
    keytool -list -v -keystore $storeFile -storepass $storePassword -alias $keyAlias
}

# 删除apk中的签名信息
# $1 是apk的路径
function removeSignV1Info() {
    checkValidApk "$1" || exit 1

    $buildToolsDir/aapt r "$1" META-INF/CERT.SF
    $buildToolsDir/aapt r "$1" META-INF/CERT.RSA
    $buildToolsDir/aapt r "$1" META-INF/MANIFEST.MF
}

# 给Apk进行V1签名
# $1 是apk文件的路径
# $1 如果为空，就是当前目录中生成的apk，
# $1 如果指定了路径，就使用指定路径的apk
function signV1() {
    local apkFile="$1"
    checkValidApk "$apkFile" || exit 1
        
    removeSignV1Info ${apkFile}

    local outputFile=$(dirname ${apkFile})/$(basename ${apkFile} .apk)_v1signed.apk

    jarsigner -verbose -keystore $storeFile -storepass $storePassword -digestalg SHA1 -sigalg MD5withRSA -sigfile CERT -signedjar "$outputFile" "$apkFile" $keyAlias
}

# 对Apk进行字节对齐优化
# $1 是apk文件的路径
# $1 如果为空，表示对当前工程中的对齐
function alignApk() {
    local apkFile="$1"
    checkValidApk $apkFile || exit 1
        
    $buildToolsDir/zipalign -v -f 4 $apkFile `dirname $apkFile`/`basename $apkFile .apk`_aligned.apk
}

#显示Apk的版本名称
# $1 是apk文件的路径
function showApkVersion() {
    local apkFile="$1"
    checkValidApk $apkFile || exit 1
    
    $buildToolsDir/aapt dump badging $apkFile | grep "version"
}

# 监测是否是一个Apk文件
# $1 是apk文件的路径
function checkValidApk() {
    apkFile="$1"

    [ -z "$apkFile" ] && apkFile=`ls *.apk | head -n 1`

    [ -z "$apkFile" ] && {
        error "no apk file in current project!"
        return 1
    }

    [ -f "$apkFile" ] || {
        error "$apkFile is not exist!"
        return 1
    }

    unzip -t "$apkFile" &> /dev/null || {
        error "$apkFile is not a apk file!"
        return 1
    }
}

#打开Genymotion模拟器
function openGenymotion() {
    player --vm-name "Google Nexus 5 - 4.4.4 - API 19 - 1080x1920" &
}

# 替换local.properties中的Android SDK路径
function setAndroidSDKHomeInLocalProperties() {
    [ -z "$ANDROID_HOME" ] && {
        error "please set ANDROID_HOME environment first!"
        exit 1
    }

    if [ "$osType" == 'Darwin' ] ; then
        sed -i ""  "s#sdk\.dir=.*#sdk.dir=${ANDROID_HOME}#g" `find ./ -name "local.properties"`
    else
        sed -i "s#sdk\.dir=.*#sdk.dir=${ANDROID_HOME}#g" `find ./ -name "local.properties"`
    fi
}

# 替换build.gradle.kts里面的版本号（versionCode）
# $1是版本号，版本号使用十位的Unix时间戳，它精确到秒，而且它不会超过Java中的int类型的最大范围（2147483647），示例：1516856238
function setVersionCodeInBuildGradle() {
    if [ "$osType" == 'Darwin' ] ; then
        sed -i ""  "s#versionCode = [0-9]\{1,10\}#versionCode = $1#g" app/build.gradle.kts
    else
        sed -i "s#versionCode = [0-9]\{1,10\}#versionCode = $1#g" app/build.gradle.kts
    fi
}

# 替换build.gradle.kts里面的包号（applicationId）
function setPackageNameInBuildGradle() {
    if [ "$osType" = 'Darwin' ] ; then
        sed -i ""  "s#applicationId = \".*\"#applicationId = \"${packageName}\"#g" app/build.gradle.kts
    else
        sed -i "s#applicationId = \".*\"#applicationId = \"${packageName}\"#g" app/build.gradle.kts
    fi
}

# 修改AndroidManifest.xml里面的android:debuggable开关
# $1 为true | false字符串
function setDebuggable() {
    origin=true
    xx=false
    if [ "$1" == "true" ] ; then
        origin=false
        xx=true
    else
        origin=true
        xx=false
    fi

    if [ "$osType" == 'Darwin' ] ;then
        sed -i ""  "s#android:debuggable=\"${origin}\"#android:debuggable=\"${xx}\"#g" app/src/main/AndroidManifest.xml
    else
        sed -i "s#android:debuggable=\"${origin}\"#android:debuggable=\"${xx}\"#g" app/src/main/AndroidManifest.xml
    fi
}

function downloadWalle() {
    info "downloading Walle..." && \
    curl -L https://github.com/Meituan-Dianping/walle/blob/master/walle-cli/walle-cli-all.jar?raw=true -o ${workDir}/tools/walle-cli.jar && \
    success "downloaded Walle!"
}

#下载360加固保
#$1是系统标志：mac|win
#$2是系统的位数
function downloadJiagu() {
    if [ "$1" == "mac" ] ; then
        info "downloading 360加固保..." && \
        curl -LO http://down.360safe.com/360Jiagu/360jiagubao_mac.zip && \
        success "downloaded 360加固保!"
    else
        info "downloading 360加固保..." && \
        curl -LO http://down.360safe.com/360Jiagu/360jiagubao_windows_$2.zip && \
        success "downloaded 360加固保!"
    fi
}

# 使用https://github.com/Meituan-Dianping/walle进行构建渠道包
# $1是apk的文件路径
function genChannels() {
    local walleCliJar=$workDir/tools/walle-cli.jar
    if [ -f "$walleCliJar" ] ; then
        unzip -t "$walleCliJar" &> /dev/null || { 
            rm "$walleCliJar" && downloadWalle || exit 1 
        }
    else
        downloadWalle || exit 1
    fi

    java -jar "$walleCliJar" batch -c 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,99 $1
}

# 使用https://github.com/shwenzhang/AndResGuard进行资源混淆
# $1是apk的文件路径
function resguard() {
    local inputApk="$1"
    local prefix=`basename "$inputApk" .apk`
    local inputDir=`dirname "$inputApk"`
    local outputDir="$inputDir/resguard"
    java -jar "$workDir/tools/AndResGuard-cli-1.2.16.jar" $1 \
         -config $workDir/AndResGuard-config.xml \
         -out "$outputDir" \
         -7zip /usr/local/bin/7za \
         -zipalign $buildToolsDir/zipalign \
         -signatureType v2 \
         -signature $storeFile $storePassword $keyPassword $keyAlias && \
    cp "$outputDir/${prefix}_7zip_aligned_signed.apk" "$inputDir/${prefix}_resguard.apk"
}
# 执行编译
# $1取值为 debug | release | develop | demo
# $2取值为--resguard，表示要混淆资源
# $3取值为--jiagu，表示要进行加固
# $4取值为--channel，表示要构建渠道包
function runBuild() {
    shift 1

    [ "debug" = "$1" -o "release" = "$1" -o "develop" = "$1" -o "demo" = "$1" ] || {
        error "environment must one of debug/release/develop/demo"
        exit 1
    }
    
    environment=$1
    isResGuard=false
    isReDex=false
    isJiaGu=false
    isGenChannels=false
    
    while true
    do
        [ $# -eq 1 ] && break
        shift 1
        if [ "$1" = "--resguard" ] ; then
            isResGuard=true
        elif [ "$1" = "--redex" ] ; then
            isReDex=true
        elif [ "$1" = "--jiagu" ] ; then
            isJiaGu=true
        elif [ "$1" = "--channel" ] ; then
            isGenChannels=true
        fi
    done
    
    info "environment   = $environment"
    info "isResGuard    = $isResGuard"
    info "isReDex       = $isReDex"
    info "isJiaGu       = $isJiaGu"
    info "isGenChannels = $isGenChannels"

    setAndroidSDKHomeInLocalProperties

    #修改版本号（版本号使用十位的Unix时间戳，它精确到秒，而且它不会超过Java中的int类型的最大范围（2147483647），示例：1516856238）
    setVersionCodeInBuildGradle $(date +%s)

    #删除掉构建目录
    rm -rf `find . -name "build"`
    #清除掉上次编译的其他临时数据
    ./gradlew clean

    if [ "$environment" == "release" ] ; then
        internalMode1="release"
        internalMode2="Release"
        setDebuggable false
    else
        internalMode1="debug"
        internalMode2="Debug"
        setDebuggable true
    fi
   
    $workDir/gradlew assemble$internalMode2 || exit 1

    rm -f *.apk
    
    local apkDir=$workDir/app/build/outputs/apk/$internalMode1
    local currentApkFile=$apkDir/app-${internalMode1}.apk

    #把图片全部替换为webp
    local unzipDir=`date +%Y%m%d%H%M%S`
    local prefix=`basename $currentApkFile .apk`
    local webpdFileName=${prefix}_webp.apk
    unzip $currentApkFile -d $apkDir/$unzipDir && \
    cd $apkDir/$unzipDir && \
    rm -rf META-INF && \
    rm -rf res/layout-watch-v20 && \
    rm -rf res/drawable-watch-v20 && \
    rm -rf res/drawable-ldrtl-mdpi-v17 && \
    rm -rf res/drawable-ldrtl-hdpi-v17 && \
    rm -rf res/drawable-ldrtl-xhdpi-v17 && \
    rm -rf res/drawable-ldrtl-xxhdpi-v17 && \
    rm -rf res/drawable-ldrtl-xxxhdpi-v17 && \
    convertToWebP && \
    7za a -tzip -mx9 $webpdFileName . && \
    signV1 $webpdFileName && \
    cp ${prefix}_webp_v1signed.apk $apkDir && \
    cd - && \
    currentApkFile=$apkDir/${prefix}_webp_v1signed.apk

    [ "$isReDex" = "true" ] && command -v redex &> /dev/null && {
        local outputFile=$apkDir/$(basename $currentApkFile .apk)_redexed.apk
        redex $currentApkFile -o $outputFile && \
        [ -f $outputFile ] && \
        currentApkFile=$outputFile
    }

    [ "$isResGuard" == "true" ] && {
        resguard "$currentApkFile" || exit 1
        currentApkFile="$apkDir/$(basename "$currentApkFile" .apk)_resguard.apk"
    }

    # 加固过程
    if [ "$isJiaGu" = "true" ] ; then
        apksigner="$buildToolsDir/apksigner"
        
        jiaguJar=""
        if [ "$osType" = "Darwin" -o "$osType" = "Linux" ] ; then
            #解压缩包，因为360加固保里包含中文，用的使用解压才能保证中文编码正确
            local x=$workDir/tools/360jiagubao_mac
            [ -d $x ] || mkdir -p $x
            cd $x
            unzip -o $workDir/tools/360jiagubao_mac.zip
            cd -
            #360加固保的zip文件中的第一层可能包含文件夹，所以，采用find的方式比较准确
            jiaguJar=`find $PWD -name "jiagu.jar"`
            chmod a+x $(dirname $(find $PWD -name "jiagu.jar"))/java/bin/java
        else
            java -version &> tmp
            local bit=`cat tmp | grep "Java HotSpot" | sed 's/^.*Java HotSpot(TM) \([0-9][0-9]\)-Bit.*/\1/'`
            rm tmp
            local x=$workDir/tools/360jiagubao_windows_${bit}
            [ -d $x ] || mkdir -p $x
            cd $x
            jar vxf $workDir/tools/360jiagubao_windows_${bit}.zip
            cd -
            jiaguJar=${x}/jiagu/jiagu.jar
            apksigner=${apksigner}.bat
        fi
        
        [ -f "$jiaguJar" ] || {
            error "$jiaguJar is not exist!"
            exit 1
        }
        
        jiagu="java -jar $jiaguJar"
        
        #登录360
        $jiagu -login $_360UserName $_360Password || {
            error "360's username or password is not correct! or there is no network!"
            exit 1
        }

        #导入签名信息
        $jiagu -importsign $storeFile $storePassword $keyAlias $keyPassword || {
            error "your keyStore is not right!"
            exit 1
        }

        #加固，并进行v1签名
        $jiagu -jiagu $currentApkFile ${apkDir} -autosign || {
            error "jiagu failed!"
            exit 1
        }

        currentApkFile=$(ls ${apkDir}/*_jiagu_sign.apk)
        outputFile=$(dirname $currentApkFile)/$(basename $currentApkFile .apk)_aligned.apk
        #字节对齐
        $buildToolsDir/zipalign -v 4 $currentApkFile $outputFile || {
            error "zipalign failed!"
            exit 1
        }

        currentApkFile=$outputFile
        outputFile=$(dirname $currentApkFile)/$(basename $currentApkFile .apk)_signed_v2.apk
        #进行v2签名
        $apksigner sign --ks $storeFile --ks-pass pass:$storePassword --ks-key-alias $keyAlias --key-pass pass:$storePassword --out $outputFile $currentApkFile || {
            error "v2 sign is failed!"
            exit 1
        }

        currentApkFile=$outputFile
        #对v2签名进行校验
        $apksigner verify --verbose $currentApkFile
    fi

    outputFile=${appName}_${versionName}_$(date +%Y%m%d_%H%M%S)_${environment}.apk
    #复制最终的apk文件，并进行渠道包的构建
    cp $currentApkFile $outputFile && [ "$isGenChannels" = "true" ] && genChannels $outputFile
}

# 显示帮助
function showHelp() {
	cat <<EOF
Usage:

./tool.sh <command> [sub-command] [option]...

./tool.sh test unit           run unit test

./tool.sh test monkey         run monkey test

./tool.sh sonar               run sonar scanner

./tool.sh show md5            show your keystore's md5

./tool.sh show version        print the apk versionCode and versionName

./tool.sh install             install the builded apk to connected device

./tool.sh uninstall           uninstall my apk form connected device

./tool.sh resguard ~/xx.apk   resguard apk

./tool.sh sign                sign my apk

./tool.sh sign ~/xx.apk       sign ~/xx.apk

./tool.sh signAlign           sign and align my apk

./tool.sh signAlign ~/xx.apk  sign and align ~/xx.apk

./tool.sh align               align my apk

./tool.sh convertToWebP       convert res/xx/*.png res/xx/*.jpg to webp Format

./tool.sh update android-sdk

./tool.sh build <environment> [option]...
    environment: 
        must be one of debug/release/develop/demo
    option: 
        --resguard   guard res, default false
        --redex      rebuild dex to optimize, default false
        --jiagu      build channels, default false
        --channel    build channels, default false
    examples: 
        ./tool.sh build debug
        ./tool.sh build release --resguard --jiagu --channel
EOF
    exit 1
}

function doctor() {
    #check JDK
    command -v java &> /dev/null
    if [ $? -eq 0 ] ; then
        java -version &> tmp
        success "JDK"
        cat tmp | while read line
        do
            echo "      $line"
        done
        rm tmp
    else
        error "JDK"
        echo "      not installed."
    fi
    
    #check JAVA_HOME
    if [ -z "$JAVA_HOME" ] ; then
        error "JAVA_HOME"
        echo "      not set."
    else
        if [ -d "$JAVA_HOME" ] ; then
            success "JAVA_HOME"
            echo "      $JAVA_HOME"
        else
            error "JAVA_HOME"
            echo "      $JAVA_HOME"
            echo "      JAVA_HOME must be a directory!"
        fi
    fi
    
    #check Android SDK
    command -v sdkmanager &> /dev/null
    if [ $? -eq 0 ] ; then
        success "Android SDK"
    else
        error "Android SDK"
    fi

    #check ANDROID_HOME
    if [ -z "$ANDROID_HOME" ] ; then
        error "ANDROID_HOME environment variable not set!"
    else
        if [ -d "$ANDROID_HOME" ] ; then
            success "ANDROID_HOME"
            echo "      $ANDROID_HOME"
        else
            error "ANDROID_HOME"
            echo "      $ANDROID_HOME"
            echo "      ANDROID_HOME must be a directory!"
        fi
    fi
    
}

function main() {
    [ -z "$1" ] && showHelp
    
    initValues
     
    case $1 in
        "doctor")
            doctor
            ;;
        "test")
            if [ "$2" == 'unit' ] ; then
		        testWithUnit
	        elif [ "$2" == 'monkey' ] ; then
		        testWithMonkey
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
            if [ "$2" == 'md5' ] ; then
                showCertificateFingerprints
	        elif [ "$2" == 'version' ] ; then
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
	        signApk "$2" && alignApk
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
            if [ "$2" == 'android-sdk' ] ; then
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
