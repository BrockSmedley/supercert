#!/bin/bash
# cleanup.sh
# cleans up current directory for a fresh start; used after testing certme.sh

rm -f easy-rsa.tar.gz
rm -rf easy-rsa-master
rm -f ./*.crt ./*.key ./*.pem

echo "Your directory is clean!"
