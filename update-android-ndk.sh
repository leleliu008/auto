#!/bin/sh

set -ex

cd ~/github.com/

for d in uppm-package-repository-linux-x86_64 uppm-package-repository-macos-*-x86_64 uppm-package-repository-macos-*-arm64
do
    printf '\n\n'

    cd "$d/formula"

    git pull --rebase=true

    for r in 30 29 28c 27d
    do
        VERSION="r$r"
        PKGNAME="android-ndk-$VERSION"

        f="$PKGNAME.yml"

        XX="${d#uppm-package-repository-}"
        OSTYPE="${XX%%-*}"

        case $r in
            30)
                case $OSTYPE in
                    linux) SHA256SUM=753611f410d002cfcd3f3dc2ef49aad532089d3180b436c060a90bf0fcb64df2 ;;
                    macos) SHA256SUM=d125634de97b26deb1e1bb1a562f9d839aa5803d1784a1e414485f5ccbe6739f ;;
                esac
                ;;
            29)
                case $OSTYPE in
                    linux) SHA256SUM=4abbbcdc842f3d4879206e9695d52709603e52dd68d3c1fff04b3b5e7a308ecf ;;
                    macos) SHA256SUM=ce5e4b100ec5fe5be4eb3edcb2c02528824ff9cda3860f5304619be6c3da34d3 ;;
                esac
                ;;
            28c)
                case $OSTYPE in
                    linux) SHA256SUM=dfb20d396df28ca02a8c708314b814a4d961dc9074f9a161932746f815aa552f ;;
                    macos) SHA256SUM=0d4599e8bbf1a1668a0d51a541729b2246360f350018a2081d0b302dbb594f2a ;;
                esac
                ;;
            27d)
                case $OSTYPE in
                    linux) SHA256SUM=601246087a682d1944e1e16dd85bc6e49560fe8b6d61255be2829178c8ed15d9 ;;
                    macos) SHA256SUM=e69092f9d2bfa5d1199039980a14eb91c03cc971ab5c6968fc08a8e6b84e7bb7 ;;
                esac
                ;;
        esac

        if [ "$OSTYPE" = macos ] ; then
            OSTYPE=darwin
        fi

        tee "$f" <<EOF
summary: A toolset that lets you implement parts of your Android app in native code
webpage: https://developer.android.com/ndk
bin-url: https://dl.google.com/android/repository/android-ndk-$VERSION-$OSTYPE.zip
bin-sha: $SHA256SUM
version: $VERSION
EOF

        S="$(git status -s -- "$f")"

        if [ -z "$S" ] ; then
            continue
        fi

        case "${S#' '}" in
            M*)
                git add "$f"
                git commit -m "update package $PKGNAME"
                git push
                ;;
            A*)
                git add "$f"
                git commit -m "addnew package $PKGNAME"
                git push
                ;;
            \?\?*)
                git add "$f"
                git commit -m "addnew package $PKGNAME"
                git push
                ;;
        esac

        printf '\n\n'
    done

    cd -
done
