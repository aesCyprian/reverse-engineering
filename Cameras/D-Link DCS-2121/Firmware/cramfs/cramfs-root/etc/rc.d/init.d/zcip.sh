#!/bin/sh

PATH=$PATH:/sbin
daemon=zcip
IFNAME=$median
SCRIPT=/etc/zcip.script

# SHOULD use "-r 169.254.x.x" to reclaim the last value
# it should have been saved away somewhere by $SCRIPT

die() {
        echo $@
        exit 1
}

start() {
	! pids=$(pidof $daemon) || die "$daemon($pids) is already running."
        echo -n "Startting $daemon... "
        [ -x $binary ] || die "$binary is not a valid application"
        export LD_LIBRARY_PATH=$prefix/lib
        $binary $IFNAME $SCRIPT > /dev/null 2> /dev/null
        echo "ok."
}

status() {
        echo -n "$daemon"
        pids=$(pidof $daemon) && echo "($pids) is running." || echo " is stop."
}

stop() {
        pids=$(pidof $daemon) || { echo "$daemon is not running." && return 1; }
        echo -n "Stopping $daemon... "
        for i in 1 2 3 4 5; do
                kill $(echo $pids | cut -d' ' -f1)
                sleep 1
                pids=$(pidof $daemon) || break
        done
        pids=$(pidof $daemon) && killall -9 $daemon && sleep 1 && pids=$(pidof $daemon) && die "ng." || echo "ok."
	[ -f "/tmp/autoip" ] && rm -f /tmp/autoip
}

action=$1
prefix=$2
end=$3

[ "$end" = "" ] && [ "$action" != "" ] || showUsage
[ "$prefix" = "" ] || [ -d "$prefix" ] || die "$prefix is not a valid directory"

binary=$prefix/sbin/$daemon

case "$action" in
start)
	start
	;;
stop)
	# FIXME should probably save and use daemon's PID
	stop || exit 1
	;;
restart)
	stop
	start
	;;
status)
	status
	;;
*)
	echo "Usage: $0 {start|stop|status|restart}"
	exit 1
	;;
esac
