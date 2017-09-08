#!/bin/bash

#------------------------------------------------------------------------------------------------------------------------
#															|
# - This script will create a self-signed certificate for you -- super duper mega easy.					|
#															|
# - This script is designed to create a certificate for the machine that it's running on, with				|
#   permissions to access whatever servers are declared in the san.csv							|
# - The san.csv is a CSV file which declares SAN items (crazy right?). Its contents should look like this:		|
#	IP:170.2.1.109,IP:10.254.0.1,DNS:myserver.us164.corpintra.net,DNS:kubernetes.default.svc.cluster.local		|
#   ! Spaces are not allowed in san.csv											| 
# 															|
# If you have CA files, you can set the ROOT_CA and ROOT_CA_KEY variables below to their respective file paths, 	|
# otherwise they should be set to 0											|
# You can also include them as arguments when running the script. Run `./certme.sh` -h for usage.			|
# 															|
# If these options are set to 0 and you don't pass any options in the command line, 					|
# the script will generate a CA for you and sign the certs with it.							|
#															|
#------------------------------------------------------------------------------------------------------------------------

# Constants
#uncomment or comment out DEBUG to enable/disable it debug readouts
#DEBUG=1
HOSTNAME=$(hostname)
CWD=$(pwd)
ROOT_CA=0
ROOT_CA_KEY=0

# Colors
RED='\033[0;31m'
BRED='\033[1;91m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# Exit constants
EXIT_HELP=3

# take arguments to input CA
if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
  echo -e "${BOLD}Usage:$NC"
  echo "    ./certme.sh [[/path/to/ca/cert/file /path/to/ca/key/file] | refresh]"
  echo
  echo "You may include existing CA files. If you leave this option out, CA files will be generated for you."
  echo "If san.csv is not present in the current directory, your certificates will be created without a SAN."
  echo
  echo -e "${BOLD}Options:$NC"
  echo -e "-\t/path/to/ca/cert/file /path/to/ca/key/file\t\tUse existing CA certificate to sign your certs. Both are required."
  echo -e "-\trefresh\t\t\t\t\t\t\tWipe the current directory of any certificate files and delete easyrsa files."
  exit $EXIT_HELP
fi

if [ "$1" == "refresh" ]; then
  echo -e "${RED}Starting fresh... ALL certificate files will be ${BRED}permanently deleted${RED} (recursively) from the current directory.$NC"
  echo -e "Are you sure you want to do this? ${BOLD}[y/N]$NC"
  read refresh_prompt
  decision="$(echo $refresh_prompt | head -c 1)"
  decision_lower="$(echo $decision | awk '{print tolower($0)}')"
  if [ "$decision_lower" == "y" ]; then
    echo -e "${GREEN}Deleting certificate files:${NC}\n$(ls *.crt *.pem *.cer *.key 2>/dev/null)"
    rm -f easy-rsa.tar.gz
    rm -rf easy-rsa-master
    rm -f *.crt *.pem *.cer *.key
  fi
  exit 0
fi

rm -f easy-rsa.tar.gz
rm -rf easy-rsa-master

if [ $1 ]; then
  ROOT_CA="$CWD/$1"
fi
if [ $2 ]; then
  ROOT_CA_KEY="$CWD/$2"
fi


if [ $DEBUG ]; then
  echo hostname: $HOSTNAME
  echo current dir: $CWD
fi

# read in SAN file -- must be named san.csv
if [ -f san.csv ]; then
  SAN=$(cat san.csv)
fi

if ! [ $SAN ]; then
  echo -e "${CYAN}Your certificates will be generated without a SAN. If you want a SAN, include san.csv in the directory and re-run the script.$NC"
  if [ $DEBUG ]; then
    echo "SAN: (empty)"
  fi
else
  if [ $DEBUG ]; then
    echo SAN:
    echo $SAN
  fi
fi
echo

### now we have our info needed to make certs. get easyrsa to generate them for us
# download and extract easyrsa
#export https_proxy=<your proxy here>
curl -L -O https://storage.googleapis.com/kubernetes-release/easy-rsa/easy-rsa.tar.gz
tar xzf easy-rsa.tar.gz
cd easy-rsa-master/easyrsa3

# initialize directory structure
./easyrsa --batch init-pki

# generate CA to create directory structure
./easyrsa --batch --req-cn=$HOSTNAME build-ca nopass
# if CA files are provided, copy them in; overwrite generated ones
if [ -f "$ROOT_CA" ] && [ -f "$ROOT_CA_KEY" ]; then
  if [ $DEBUG ]; then
    echo root CA: $ROOT_CA
    cat $ROOT_CA
    echo root CA key: $ROOT_CA_KEY
    cat $ROOT_CA_KEY
  fi
  echo -e "${CYAN}copying CA files into pki directory...$NC"
  echo root CA: $ROOT_CA
  /bin/cp -f $ROOT_CA pki/ca.crt
  echo root CA key: $ROOT_CA_KEY
  /bin/cp -f $ROOT_CA_KEY pki/private/ca.key
  echo -e "${CYAN}done copying CA files...$NC"
# otherwise generate new ones
else
  echo -e "${CYAN}generating CA files...$NC"
fi

# now that we have our CA in place we can start generating some certs
if [ $SAN ]; then
  SAN_ARG=" --subject-alt-name=$SAN "
else
  SAN_ARG=' '
fi

./easyrsa${SAN_ARG}build-server-full $HOSTNAME nopass
# easyrsa doesn't allow extra space between arguments so we have to be very particular

if [ $DEBUG ]; then
  # display cert information
  openssl x509 -noout -text -in "pki/issued/$HOSTNAME.crt"
fi

# lastly, make symbolic links to the files for easy access
ln -s "$CWD/easy-rsa-master/easyrsa3/pki/issued/$HOSTNAME.crt" "$CWD/$HOSTNAME.crt" 2>/dev/null
ln -s "$CWD/easy-rsa-master/easyrsa3/pki/private/$HOSTNAME.key" "$CWD/$HOSTNAME.key" 2>/dev/null
ln -s "$CWD/easy-rsa-master/easyrsa3/pki/ca.crt" "$CWD/ca.crt" 2>/dev/null
