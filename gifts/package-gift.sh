#!/bin/sh

osType=`uname -s`
echo "osType=$osType"

BUILD_DIR=$PWD/build
SOURCE_DIR=$BUILD_DIR/source
ZIP_DIR=$BUILD_DIR/zip

function main() {
    #如果存在build目录，就删除掉
    if [ -d $BUILD_DIR ] ; then
        rm -rf $BUILD_DIR
    fi
    
    #获得所有的礼物文件夹
    giftDirs=`ls -F | grep "/$"`
    
    #重新创建build目录及其子目录
    mkdir -p $SOURCE_DIR
    mkdir -p $ZIP_DIR

    #复制所有的礼物文件夹到build/source目录
    for giftDir in $giftDirs
    do
        giftDir=`basename $giftDir`
        rm ${giftDir}/.DS_Store
        cp -r $giftDir $SOURCE_DIR/
    done
    
    cd $SOURCE_DIR

    for dir in $giftDirs
    do
        dir=`basename ${dir}`
        for imageFile in `ls ${dir}/images`
        do
            #修改成新的名字
            mv ${dir}/images/${imageFile} ${dir}/images/${dir}_${imageFile}
            #将data.json中图片名称替换成新的
            if [ $osType = 'Darwin' ] ; then
                sed -i ""  "s#${imageFile}#${dir}_${imageFile}#g" ${dir}/data.json
            else
                sed -i "s#${imageFile}#${dir}_${imageFile}#g" ${dir}/data.json
            fi
        done
        #打zip包
        zip -r $ZIP_DIR/${dir}.zip $dir
    done
    echo "Success Done"
}

main
