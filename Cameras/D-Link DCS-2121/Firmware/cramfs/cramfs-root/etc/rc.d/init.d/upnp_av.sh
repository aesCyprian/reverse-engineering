#!/bin/sh

daemon=orthrus
PATH=$PATH:/sbin

die() {
	echo $@
	exit 1
}

showUsage() {
	die "$0 {start|stop|restart|status} [prefix]"
}

dumpSystemKeys() {
	echo -n "\
OEM_ms
OEMUrl_ms
ProdName_ms
Model_ss
ProdNumber_ss
ProdNameW_ms
ModelW_ss
ProdNumberW_ss
"
}

dumpUPnPKeys() {
	echo -n "\
Enable_byte
PortForward_byte
"
}

probeLink() {
	mii-tool $1 2> /dev/null | grep -q 'link ok'
}

probeWireless() {
	[ "$(pibinfo Wireless)" -eq 1 ]
}

start() {
	! pids=$(pidof $daemon) || die "$daemon($pids) is already running."
	echo -n "Startting $daemon... "
	[ -x $binary ] || die "$binary is not a valid application"
	export LD_LIBRARY_PATH=$prefix/lib

	WLANEnable_byte=`tdb get Wireless Enable_byte`
	CameraName=`tdb get Host CameraName_ms`

	if probeLink || [ "$linkage" = "up" ]; then
		median=eth0
	elif [ "$WLANEnable_byte" -eq 1 ] && probeWireless; then
		median=ra0
	else
		median=eth0
	fi
	
	eval $(dumpUPnPKeys | tdb get UPnP)
	if [ $Enable_byte -eq 0 ]; then
		echo "disabled."
	else
		eval $(dumpSystemKeys | tdb get System)
		if [ "$(pibinfo Wireless)" -eq 1 ]; then
			$binary -i $median "$debug" -f "$CameraName" -p "$ProdNameW_ms" -n "$ModelW_ss" -m "$OEM_ms" -u "$OEMUrl_ms" > /dev/null 2> /dev/null &
		else
			$binary -i $median "$debug" -f "$CameraName" -p "$ProdName_ms" -n "$Model_ss" -m "$OEM_ms" -u "$OEMUrl_ms" > /dev/null 2> /dev/null &
		fi
	fi
	echo "ok."
}


status() {
	echo -n "$daemon"
	pids=$(pidof $daemon) && echo "($pids) is running." || echo " is stop."
}


stop() {
	pids=$(pidof $daemon) || { echo "$daemon is not running." && return 1; }
	echo -n "Stopping $daemon... "
	kill $(echo $pids | cut -d' ' -f1)
	sleep 1
	pids=$(pidof $daemon) && killall -9 $daemon && sleep 1 && pids=$(pidof $daemon) && die "ng." || echo "ok."
}

action=$1
prefix=$2
end=$3
debug=$4

[ "$end" = "" ] && [ "$action" != "" ] || showUsage
[ "$prefix" = "" ] || [ -d "$prefix" ] || die "$prefix is not a valid directory"

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
		sleep 1
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

