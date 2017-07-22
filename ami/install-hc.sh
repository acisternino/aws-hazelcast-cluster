#!/bin/bash
set -e

# WARNING!
# This script is meant to be run as root!

# Configuration values
HC_ALL_VERSION=3.8.3
HC_AWS_VERSION=2.0.1

HC_USER=hazelcast
HC_HOME=/opt/$HC_USER

SLF4J_VERSION=1.7.25
LOGBACK_VERSION=1.2.3

MAVEN_REPO=http://central.maven.org/maven2

# Java
echo "Installing Java"
apt-get -y -qq install openjdk-8-jre-headless 1> /dev/null

# Hazelcast
echo "Adding \"$HC_USER\" user"
useradd -b /opt -m -r -s /bin/false $HC_USER
chmod 755 $HC_HOME

echo "Preparing log directory"
mkdir /var/log/hazelcast
chown ${HC_USER}.${HC_USER} /var/log/hazelcast

# These are downloaded to the default home directory and later moved to the correct place
echo "Downloading Hazelcast artifacts"
curl -sS -O ${MAVEN_REPO}/com/hazelcast/hazelcast-all/${HC_ALL_VERSION}/hazelcast-all-${HC_ALL_VERSION}.jar
curl -sS -O ${MAVEN_REPO}/com/hazelcast/hazelcast-aws/${HC_AWS_VERSION}/hazelcast-aws-${HC_AWS_VERSION}.jar

echo "Downloading logging artifacts"
curl -sS -O ${MAVEN_REPO}/org/slf4j/slf4j-api/${SLF4J_VERSION}/slf4j-api-${SLF4J_VERSION}.jar
curl -sS -O ${MAVEN_REPO}/ch/qos/logback/logback-core/${LOGBACK_VERSION}/logback-core-${LOGBACK_VERSION}.jar
curl -sS -O ${MAVEN_REPO}/ch/qos/logback/logback-classic/${LOGBACK_VERSION}/logback-classic-${LOGBACK_VERSION}.jar

# Move things to the proper place
if [[ -d "$HC_HOME" ]]; then

    echo "Moving Hazelcast files to \"$HC_HOME\""

    # Jars go into lib
    mkdir -p $HC_HOME/lib
    mv -v *.jar $HC_HOME/lib

    mv -v *.xml *.sh *.conf $HC_HOME
    chmod 755 $HC_HOME/*.sh

    echo "Fixing owner"
    chown -R ${HC_USER}.${HC_USER} $HC_HOME/*

    echo "Final status"
    tree -pfs $HC_HOME
else
    echo "Error: home directory \"$HC_HOME\" not found!"
    exit 1
fi

# Copy systemd unit to right place
echo "Configuring systemd service"
cp hazelcast.service /etc/systemd/system
chmod 664 /etc/systemd/system/hazelcast.service

# Configure the daemon
systemctl daemon-reload
systemctl enable hazelcast
