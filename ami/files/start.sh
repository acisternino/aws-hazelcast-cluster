#!/bin/bash
set -e

HAZELCAST_HOME=$(dirname "$0")

if [[ $JAVA_HOME ]]; then
    echo "JAVA_HOME found at $JAVA_HOME"
    RUN_JAVA=$JAVA_HOME/bin/java
else
    echo "JAVA_HOME environment variable not available."
    RUN_JAVA=$(type -p java)
fi

if [[ -z $RUN_JAVA ]]; then
    echo "JAVA could not be found in your system."
    echo "Please install Java 1.7 or higher!!!"
    exit 1
fi

echo "Path to Java: \"$RUN_JAVA\""

#### you can enable following variables by uncommenting them

#### minimum heap size
# MIN_HEAP_SIZE=1G

#### maximum heap size
# MAX_HEAP_SIZE=1G

if [[ "x$MIN_HEAP_SIZE" != "x" ]]; then
    JAVA_OPTS="$JAVA_OPTS -Xms${MIN_HEAP_SIZE}"
fi

if [[ "x$MAX_HEAP_SIZE" != "x" ]]; then
    JAVA_OPTS="$JAVA_OPTS -Xmx${MAX_HEAP_SIZE}"
fi

# append other tuning options to JAVA_OPTS

echo "########################################"
echo "# Hazelcast server"
echo "# RUN_JAVA=$RUN_JAVA"
echo "# JAVA_OPTS=$JAVA_OPTS"
echo "# HAZELCAST_HOME=$HAZELCAST_HOME"
echo "# Starting now...."
echo "########################################"

cd $HAZELCAST_HOME
$RUN_JAVA -server $JAVA_OPTS -cp '.:lib/*' com.hazelcast.core.server.StartServer
