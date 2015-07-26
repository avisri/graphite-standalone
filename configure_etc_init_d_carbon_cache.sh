#!/bin/bash 

cat > /etc/init.d/carbon-cache <<\EOF
#!/bin/bash
# chkconfig:   - 25 75
# description: carbon-cache
# processname: carbon-cache

export PYTHONPATH="$GRAPHITE_DIR/lib:$PYTHONPATH"

# Source function library.
if [ -e /etc/rc.d/init.d/functions ]; then
    . /etc/rc.d/init.d/functions;
fi;

CARBON_DAEMON="cache"
GRAPHITE_DIR="/opt/graphite"
INSTANCES=`grep "^\[${CARBON_DAEMON}" ${GRAPHITE_DIR}/conf/carbon.conf | cut -d \[ -f 2 | cut -d \] -f 1 | cut -d : -f 2`

function die {
  echo $1
  exit 1
}

start(){
    cd $GRAPHITE_DIR;

    for INSTANCE in ${INSTANCES}; do
        if [ "${INSTANCE}" == "${CARBON_DAEMON}" ]; then
            INSTANCE="a";
        fi;
        echo "Starting carbon-${CARBON_DAEMON}:${INSTANCE}..."
        bin/carbon-${CARBON_DAEMON}.py --instance=${INSTANCE} start;

        if [ $? -eq 0 ]; then
            echo_success
        else
            echo_failure
        fi;
        echo ""
    done;
}

stop(){
    cd $GRAPHITE_DIR

    for INSTANCE in ${INSTANCES}; do
        if [ "${INSTANCE}" == "${CARBON_DAEMON}" ]; then
            INSTANCE="a";
        fi;
        echo "Stopping carbon-${CARBON_DAEMON}:${INSTANCE}..."
        bin/carbon-${CARBON_DAEMON}.py --instance=${INSTANCE} stop

        if [ `sleep 3; /usr/bin/pgrep -f "carbon-${CARBON_DAEMON}.py --instance=${INSTANCE}" | /usr/bin/wc -l` -gt 0 ]; then
            echo "Carbon did not stop yet. Sleeping longer, then force killing it...";
            sleep 20;
            /usr/bin/pkill -9 -f "carbon-${CARBON_DAEMON}.py --instance=${INSTANCE}";
        fi;

        if [ $? -eq 0 ]; then
            echo_success
        else
            echo_failure
        fi;
        echo ""
    done;
}

status(){
    cd $GRAPHITE_DIR;

    for INSTANCE in ${INSTANCES}; do
        if [ "${INSTANCE}" == "${CARBON_DAEMON}" ]; then
            INSTANCE="a";
        fi;
        bin/carbon-${CARBON_DAEMON}.py --instance=${INSTANCE} status;
    
        if [ $? -eq 0 ]; then
            echo_success
        else
            echo_failure
        fi;
        echo ""
    done;
}

case "$1" in
  start)
    start 
    ;;
  stop)
    stop
    ;;
  status)
    status
    ;;
  restart|reload)
    stop
    start
    ;;
  *)
    echo $"Usage: $0 {start|stop|restart|status}"
    exit 1
esac
EOF

#Add to chkconfig
chmod +x /etc/init.d/carbon-cache
chkconfig --add carbon-cache
chkconfig carbon-cache  on 

