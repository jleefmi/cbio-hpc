#!/bin/bash

set -x
set -e

## ENSURE THESE VARIABLES ARE CORRECT ##
export CS_VERSION=6.8.1
export CYCLECLOUD_LOCKER=fm-ae1-cyclecloud-poc
##

export CS_HOME=/opt/cycle_server
export INSTALL_DIR=/tmp/cyclecloud
mkdir -p ${INSTALL_DIR}
chmod a+rwX ${INSTALL_DIR}

echo "Bootstrapping CycleCloud..."
echo "Fetching CycleCloud Bootstrap script..."

yum -y update
yum -y install epel-release
yum install -y python-pip java-1.8.0-openjdk.x86_64 unzip

pip install -U pip awscli pystache argparse python-daemon requests

cd ${INSTALL_DIR}
aws s3 cp --recursive s3://${CYCLECLOUD_LOCKER}/installers/${CS_VERSION}/ .
tar xzf cyclecloud*tar.gz
tar xzf pogo*tar.gz
tar xzf cycle_server-all*tar.gz
mv cyclecloud /usr/local/bin/
mv pogo /usr/local/bin/

pushd cycle_server/
./install.sh --nostart
popd


### Copy cyclecloud configuration files ###

chown cycle_server:cycle_server ${INSTALL_DIR}/cyclecloud_init.txt
chown cycle_server:cycle_server ${INSTALL_DIR}/users_init.txt
cp ${INSTALL_DIR}/cyclecloud_init.txt ${CS_HOME}/config/data
cp ${INSTALL_DIR}/users_init.txt ${CS_HOME}/config/data

cd ${CS_HOME}

###Create Self Signed Cert###
echo "${cyn}Create self-signed SSL cert...${end}";
keytool -genkey \
-keyalg RSA \
-sigalg SHA256withRSA \
-alias CycleServer \
-dname "CN=Foundation Medicine, OU=IT, O=Foundation Medicine, L=Cambridge, ST=MA, C=US" \
-keypass "SelfSignedUseOnlyPlease" \
-keystore .keystore \
-storepass "SelfSignedUseOnlyPlease"

#mv .keystore ${CS_HOME}/
chown cycle_server:cycle_server ${CS_HOME}/.keystore

### Set ports and HTTPS ###
sed -i 's/^webServerKeystorePass=changeit/webServerKeystorePass=SelfSignedUseOnlyPlease/' ${CS_HOME}/config/cycle_server.properties
sed -i '/^webServerMaxHeapSize/c webServerMaxHeapSize=8192M' ${CS_HOME}/config/cycle_server.properties
sed -i '/^webServerPort/c webServerPort=80' ${CS_HOME}/config/cycle_server.properties
sed -i '/^webServerSslPort/c webServerSslPort=443' ${CS_HOME}/config/cycle_server.properties
sed -i '/^brokerMaxHeapSize/c brokerMaxHeapSize=2048M' ${CS_HOME}/config/cycle_server.properties
sed -i '/^webServerEnableHttp=/c webServerEnableHttp=false' ${CS_HOME}/config/cycle_server.properties
sed -i '/^webServerEnableHttps=/c webServerEnableHttps=true' ${CS_HOME}/config/cycle_server.properties

### Create the SSH Keystore ###
#/bin/keytool -genkey -keyalg RSA -sigalg SHA256withRSA -alias CycleServer -keypass "changeit" -keystore .keystore -storepass "changeit"

echo "Starting CycleCloud..."
${CS_HOME}/cycle_server start --wait
