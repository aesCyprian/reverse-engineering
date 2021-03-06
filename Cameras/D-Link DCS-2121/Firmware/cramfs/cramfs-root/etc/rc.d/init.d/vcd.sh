#!/bin/sh

daemon=vcd
PATH=$PATH:/sbin

die() {
	echo $@
	exit 1
}

showUsage() {
	die "$0 {start|stop|restart|status|reload} [prefix]"
}

start() {
	! pids=$(pidof $daemon) || die "$daemon($pids) is already running."
	echo -n "Startting $daemon... "
	[ -x $binary ] || die "$binary is not a valid application"
	export LD_LIBRARY_PATH=$prefix/lib
	$binary > /dev/null 2> /dev/null &
	[ -x $detecter ] && $detecter > /dev/null 2> /dev/null &
	echo "ok."
}

status() {
	echo -n "$daemon"
	pids=$(pidof $daemon) && echo "($pids) is running." || echo " is stop."
}

reload() {
	pids=$(pidof $daemon) || { echo "$daemon is not running." && return 1; }
	echo -n "Reloading $daemon... "
	kill -s SIGUSR1 $(echo $pids | cut -d' ' -f1)
	echo "ok."
}

stop() {
	pids=$(pidof $daemon) || { echo "$daemon is not running." && return 1; }
	echo -n "Stopping $daemon... "
	[ -x $detecter ] && killall detecter
	kill $(echo $pids | cut -d' ' -f1)
	sleep 1
	pids=$(pidof $daemon) && killall -9 $daemon && sleep 1 && pids=$(pidof $daemon) && die "ng." || echo "ok."
}

mask_reload() {
	pids=$(pidof $daemon) || { echo "$daemon is not running." && return 1; }
	echo -n "Mask Reload $daemon... "
	kill -s SIGUSR2 $(echo $pids | cut -d' ' -f1)
	echo "ok."
}

action=$1
prefix=$2
end=$3

[ "$end" = "" ] && [ "$action" != "" ] || showUsage
[ "$prefix" = "" ] || [ -d "$prefix" ] || die "$prefix is not a valid directory"

binary=$prefix/sbin/$daemon
detecter=$prefix/sbin/detecter

case $action in
	privatemask)
		mask_reload
	;;
	reload)
		#reload || exit 1
		stop
		start
	;;
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
	status)
		status
	;;
	*)
		showUsage
	;;
esac

exit 0
