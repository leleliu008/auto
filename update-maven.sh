#!/bin/sh

set -ex

CWD="$PWD"

curl -LO https://formulae.brew.sh/api/formula/maven.json

VERSION="$(jq -r '.versions.stable' maven.json)"

VERSION_MAJOR="${VERSION%%.*}"

BIN_URL="https://dlcdn.apache.org/maven/maven-$VERSION_MAJOR/$VERSION/binaries/apache-maven-$VERSION-bin.tar.gz"

curl -LO "$BIN_URL"

FILENAME="${BIN_URL##*/}"

SHA256SUM="$(sha256sum "$FILENAME")"

BIN_SHA="${SHA256SUM%% *}"

tee maven.yml <<EOF
summary: A Java-based project management and comprehension tool
webpage: https://maven.apache.org/
bin-url: $BIN_URL
bin-sha: $BIN_SHA
version: $VERSION
dep-pkg: jdk21 gsed
install: |
    JDK_INSTALL_DIR="\${PKG_INSTALL_DIR%/*}/jdk21"

    for f in bin/mvn bin/mvnDebug bin/mvnyjp
    do
        gsed -i "1a export JAVA_HOME='\$JDK_INSTALL_DIR'" "\$f"
    done
EOF

for d in uppm-package-repository-*
do
    cd "$HOME/github.com/$d/formula"

    git pull

    cp "$CWD/maven.yml" .

    S="$(git status -s -- maven.yml)"

    case "${S#' '}" in
        M*)
            VOLD="$(git diff -U0 maven.yml | grep '^-version: ' | cut -c11-)"

            git add maven.yml
            git commit -m "update package maven $VOLD -> $VERSION"
            git push
            ;;
        A*)
            git add maven.yml
            git commit -m "addnew package maven $VERSION"
            git push
            ;;
        \?\?*)
            git add maven.yml
            git commit -m "addnew package maven $VERSION"
            git push
            ;;
    esac
done
