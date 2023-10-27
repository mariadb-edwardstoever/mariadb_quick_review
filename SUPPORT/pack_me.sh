#!/usr/bin/env bash
# pack_me.sh
# file distributed with mariadb_quick_review
# By Edward Stoever for MariaDB Support


# Establish working directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"


if [ ! -f ${SCRIPT_DIR}/import_quick_review.sh ]; then echo "where is the import_quick_review.sh file?"; exit 1; fi
cd $SCRIPT_DIR/
rm -f QK-*.tar.gz
rm -f unpack_me*
zip -r -P grantmeaccess unpack_me.zip ./*

find . -type f ! -name unpack_me.zip -exec rm -f {} \;
rmdir old_versions/*
rmdir old_versions
rmdir OPT
rmdir SQL

mv unpack_me.zip unpack_me

echo "use command: unzip unpack_me"
echo "PASSWORD: grantmeaccess"
