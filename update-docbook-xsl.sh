#!/bin/sh

set -ex

for d in uppm-package-repository-*
do
    cd "$HOME/github.com/$d/formula"

    git pull

    cp ~/github.com/docbook-xsl.yml .

    git add docbook-xsl.yml

    case "$(git status -s -- docbook-xsl.yml)" in
        'A  docbook-xsl.yml')
            git commit -m 'add package : docbook-xsl'
            git push
            ;;
        'M  docbook-xsl.yml')
            git commit -m 'update package : docbook-xsl'
            git push
            ;;
    esac
done
