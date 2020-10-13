#!/bin/sh

die() {
	echo $@
	exit 1
}

showUsage() {
	die "$0 {start|stop|restart|status} [prefix]"
}

# start order
# recorderd, snapshotd -> eventd -> watchDog, motiond
# recorderd, snapshotd, watchDog, motiond -> scheduled
start() {
	echo start services, ...
	
	$prefix/etc/rc.d/init.d/rtpd.sh start $prefix
	$prefix/etc/rc.d/init.d/rtspd.sh start $prefix
	$prefix/etc/rc.d/init.d/recorderd.sh start $prefix
	
	eval $(dumppibinfoKeys | pibinfo Peripheral)
	if [ "$PT" -eq 1 ]; then
		$prefix/etc/rc.d/init.d/patrold.sh start $prefix
		#echo "start patrold."
	fi
	
	$prefix/etc/rc.d/init.d/scheduled.sh start $prefix
	$prefix/etc/rc.d/init.d/upnp_av.sh start $prefix
}

status() {
	echo status of services, ...
	$prefix/etc/rc.d/init.d/rtpd.sh status $prefix
	$prefix/etc/rc.d/init.d/rtspd.sh status $prefix
	$prefix/etc/rc.d/init.d/recorderd.sh status $prefix
	
	eval $(dumppibinfoKeys | pibinfo Peripheral)
	if [ "$PT" -eq 1 ]; then
		$prefix/etc/rc.d/init.d/patrold.sh status $prefix
	fi
	
	$prefix/etc/rc.d/init.d/scheduled.sh status $prefix
}

stop() {
	echo stop services, ...
	$prefix/etc/rc.d/init.d/upnp_av.sh stop $prefix
	$prefix/etc/rc.d/init.d/scheduled.sh stop $prefix
	
	eval $(dumppibinfoKeys | pibinfo Peripheral)
	if [ "$PT" -eq 1 ]; then
		$prefix/etc/rc.d/init.d/patrold.sh stop $prefix
		#echo "stop patrold."
	fi
	
	$prefix/etc/rc.d/init.d/recorderd.sh stop $prefix
	$prefix/etc/rc.d/init.d/rtspd.sh stop $prefix
	$prefix/etc/rc.d/init.d/rtpd.sh stop $prefix
}

existRestart() {
	echo existRestart services, ...
	eval $(dumppibinfoKeys | pibinfo Peripheral)
	pidUpnp=$(pidof upnp_av) && /etc/rc.d/init.d/upnp_av.sh stop
	pidScheduled=$(pidof scheduled) && /etc/rc.d/init.d/scheduled.sh stop
	
	if [ "$PT" -eq 1 ]; then
		pidPatrold=$(pidof patrold) && /etc/rc.d/init.d/patrold.sh stop
		#echo "stop patrold."
	fi
	
	pidRecorderd=$(pidof recorderd) && /etc/rc.d/init.d/recorderd.sh stop
	pidRtspd=$(pidof rtspd) && /etc/rc.d/init.d/rtspd.sh stop
	pidRtpd=$(pidof rtpd) && /etc/rc.d/init.d/rtpd.sh stop

	[ "$pidRtpd" != "" ] && $prefix/etc/rc.d/init.d/rtpd.sh start $prefix
	[ "$pidRtspd" != "" ] && $prefix/etc/rc.d/init.d/rtspd.sh start $prefix
	[ "$pidRecorderd" != "" ] && $prefix/etc/rc.d/init.d/recorderd.sh start $prefix
	
	if [ "$PT" -eq 1 ]; then
		[ "$pidPatrold" != "" ] && $prefix/etc/rc.d/init.d/patrold.sh start $prefix
		#echo "start patrold."
	fi
	
	[ "$pidScheduled" != "" ] && $prefix/etc/rc.d/init.d/scheduled.sh start $prefix
	[ "$pidUpnp" != "" ] && $prefix/etc/rc.d/init.d/upnp_av.sh start $prefix
	addlog System time is set directly with NTP time, some time-based services may be restarted.
}

dumppibinfoKeys() {
	echo -n "\
GPINs
GPOUTs
Speaker
Microphone
EchoCanceller
PT
Z
privacy
RS485
IR
VideoServer
LocalStorage
FrontLED
PIR
Wireless
"
}

action=$1
prefix=$2
end=$3

[ "$end" = "" ] && [ "$action" != "" ] || showUsage
[ "$prefix" = "" ] || [ -d "$prefix" ] || die "$prefix is not a valid directory"

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
	status)
		status
	;;
	existRestart)
		existRestart
	;;
	*)
		showUsage
	;;
esac

exit 0
