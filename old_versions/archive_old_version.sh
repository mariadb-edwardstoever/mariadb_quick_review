#!/bin/bash 
# Script by Edward Stoever for MariaDB Support
# Takes a archive old version of Mariadb Quick Review
EPOCH=$(date +%s)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd $SCRIPT_DIR/../..
find ./mariadb_quick_review \( -path ./mariadb_quick_review/old_versions -o -path ./mariadb_quick_review/.git \) -prune -o -type f ! -name "*.tar.gz" | cpio -ov | bzip2 > ${SCRIPT_DIR}/quick_review_archive_${EPOCH}.cpio.bz2
if [ -f ${SCRIPT_DIR}/quick_review_archive_${EPOCH}.cpio.bz2 ]; then
echo "Archive created:"; ls -l ${SCRIPT_DIR}/quick_review_archive_${EPOCH}.cpio.bz2;
else
  echo "Something did not go as planned"; exit 1
fi
