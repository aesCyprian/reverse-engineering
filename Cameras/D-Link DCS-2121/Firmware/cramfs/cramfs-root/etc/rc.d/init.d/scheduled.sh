#!/bin/sh

daemon=scheduled
PATH=$PATH:/sbin

die() {
	echo $@
	exit 1
}

showUsage() {
	die "$0 {start|stop|restart|status} [prefix]"
}

start() {
	! pids=$(pidof $daemon) || die "$daemon($pids) is already running."
	echo -n "Startting $daemon... "
	[ -x $binary ] || die "$binary is not a valid application"
	export LD_LIBRARY_PATH=$prefix/lib
	$binary > /dev/null 2> /dev/null &
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
}

reload() {
	/bin/send_cmd "$daemon" 200 || die "$daemon is not running."
}

action=$1
prefix=$2
end=$3

[ "$end" = "" ] && [ "$action" != "" ] || showUsage
[ "$prefix" = "" ] || [ -d "$prefix" ] || die "$prefix is not a valid directory"

conf=$prefix/etc/$daemon.conf
binary=$prefix/sbin/$daemon

case $action in
	start)
		start
	;;
	stop)
		# stop may call return, instead of exit
		stop || exit 1
	;;
	restart)
		stop
		start
	;;
	reload)
		reload
	;;
	status)
		status
	;;
	*)
		showUsage
	;;
esac

exit 0
