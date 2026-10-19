#!/bin/sh

set -ex

curl -L -o zig.json https://ziglang.org/download/index.json

JSON="$PWD/zig.json"


for VERSION in '0.14.1' '0.15.2' '0.16.0' '0.17.0'
do
    PKGNAME="zig@${VERSION%.*}"
    FILENAME="$PKGNAME.yml"

    for TUPLE in x86_64-macos aarch64-macos x86_64-linux aarch64-linux riscv64-linux powerpc64le-linux loongarch64-linux s390x-linux
    do
        OSNAME="${TUPLE#*-}"
        OSARCH="${TUPLE%-*}"

        case $OSNAME in
            macos)
                if [ "$OSARCH" = aarch64 ] ; then
                    OSARCH=arm64
                fi

                DIRS="$(find -maxdepth 1 -mindepth 1 -type d -name "uppm-package-repository-macos-*-$OSARCH" -printf '%P\n')"
                ;;
            linux)
                if [ "$OSARCH" = powerpc64le ] ; then
                    DIRS="uppm-package-repository-linux-ppc64le"
                else
                    DIRS="uppm-package-repository-linux-$OSARCH"
                fi
                ;;
        esac

        for d in $DIRS
        do
            cd "$HOME/github.com/$d/formula"

            git pull

            BIN_URL="$(jq -r ".\"$VERSION\".\"$TUPLE\".tarball" "$JSON")"
            BIN_SHA="$(jq -r ".\"$VERSION\".\"$TUPLE\".shasum"  "$JSON")"

            tee "$FILENAME" <<EOF
summary: A general-purpose programming language and toolchain for maintaining robust, optimal and reusable software
webpage: https://ziglang.org/
bin-url: $BIN_URL
bin-sha: $BIN_SHA
version: $VERSION
unpackd: bin
EOF

            S="$(git status -s -- "$FILENAME")"

            if [ -z "$S" ] ; then
                cd -
                continue
            fi

            case "${S#' '}" in
                M*)
                    VOLD="$(git diff -U0 "$FILENAME" | grep '^-version: ' | cut -c11-)"

                    if [ -z "$VOID" ] ; then
                        XXXX=
                    else
                        XXXX=" $VOLD -> $VERSION"
                    fi

                    git add "$FILENAME"
                    git commit -m "update package ${PKGNAME}${XXXX}"
                    git push
                    ;;
                A*)
                    git add "$FILENAME"
                    git commit -m "addnew package ${PKGNAME} ${VERSION}"
                    git push
                    ;;
                \?\?*)
                    git add "$FILENAME"
                    git commit -m "addnew package ${PKGNAME} ${VERSION}"
                    git push
                    ;;
            esac

            cd -
        done
    done
done
