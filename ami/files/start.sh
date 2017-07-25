#!/bin/bash
#
# Hazelcast starter script

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

# set G1 garbage collector
JAVA_OPTS="-XX:+UseG1GC"

# find optimal heap size
mem_perc=0.85        # 85% of available memory

avail_mem=$(awk "/^MemAvailable/ { printf \"%d\", \$2 * $mem_perc / 1024 }" /proc/meminfo)

JAVA_OPTS="$JAVA_OPTS -Xms$((avail_mem / 2))m -Xmx${avail_mem}m"

# append other tuning options to JAVA_OPTS

sleep 30

echo "########################################"
echo "# Hazelcast server"
echo "# RUN_JAVA=$RUN_JAVA"
echo "# JAVA_OPTS=$JAVA_OPTS"
echo "# HAZELCAST_HOME=$HAZELCAST_HOME"
echo "# Starting now...."
echo "########################################"

cd $HAZELCAST_HOME
$RUN_JAVA -server $JAVA_OPTS -cp '.:lib/*' com.hazelcast.core.server.StartServer
