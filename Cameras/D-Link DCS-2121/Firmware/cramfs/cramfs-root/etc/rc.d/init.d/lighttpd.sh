#!/bin/sh

daemon=lighttpd
PATH=$PATH:/sbin

die() {
	echo $@
	exit 1
}

showUsage() {
	die "$0 {start|stop|restart|status} [prefix]"
}

dumpAccountKey() {
	echo -n "\
_AdminUser_ss 
AdminPasswd_ss
LiveAuth_byte
SnapAuth_byte
User1_ss
Password1_ss
User2_ss
Password2_ss
User3_ss
Password3_ss
User4_ss
Password4_ss
User5_ss
Password5_ss
User6_ss
Password6_ss
User7_ss
Password7_ss
User8_ss
Password8_ss
User9_ss
Password9_ss
User10_ss
Password10_ss
User11_ss
Password11_ss
User12_ss
Password12_ss
User13_ss
Password13_ss
User14_ss
Password14_ss
User15_ss
Password15_ss
User16_ss
Password16_ss
User17_ss
Password17_ss
User18_ss
Password18_ss
User19_ss
Password19_ss
User20_ss
Password20_ss
"
}

readAccount() {
	eval $(dumpAccountKey | tdb get HTTPAccount)
}

md5hex() {
	echo -n "$1" | md5sum | cut -b -32
}

setupAdmin() {
	cat > /tmp/lighttpd-htdigest.user << EOM
$1:$model:$(md5hex "$1:$model:$2")
$1:nipca:$(md5hex "$1:nipca:$2")
$1:onvif:$(md5hex "$1:onvif:$2")
EOM
}

setupUser() {
	cat >> /tmp/lighttpd-htdigest.user << EOM
$1:$model:$(md5hex "$1:$model:$2")
$1:nipca:$(md5hex "$1:nipca:$2")
$1:onvif:$(md5hex "$1:onvif:$2")
EOM
}

setupAuth() {
# admin always need auth
cat << EOM
auth.require = (
	"/cht/admin/" =>
	(
		"method" => "basic",
		"realm" => "$model",
		"require" => "user=$_AdminUser_ss"
	),
	"/eng/admin/" =>
	(
		"method" => "basic",
		"realm" => "$model",
		"require" => "user=$_AdminUser_ss"
	),
	"/cgi/admin/" =>
	(
		"method" => "basic",
		"realm" => "$model",
		"require" => "user=$_AdminUser_ss"
	),
	"/config/" =>
	(
		"method" => "basic",
		"realm" => "nipca",
		"require" => "user=$_AdminUser_ss"
	),
	"/onvif/" =>
	(
		"method" => "basic",
		"realm" => "onvif",
		"require" => "user=$_AdminUser_ss"
	),
EOM

	# get Trendnet name 
	[ $(pibinfo Wireless) -eq 1 ] && modelname=TV-IP512WN ||  modelname=TV-IP512P
	
# valid-user depend on auth settings
if [ "$LiveAuth_byte" -eq 1 ]; then 
	# snap auth
	[ "$SnapAuth_byte" -eq 1 ] && cat << EOM
	"/image/" =>
	(
		"method" => "basic",
		"realm" => "$model",
		"require" => "valid-user"
	),
EOM

if [ "$model" != "$modelname" ];then
	cat << EOM
	"/video/" =>
	(
		"method" => "basic",
		"realm" => "$model",
		"require" => "valid-user"
	),
EOM
fi	
	# live auth
	cat << EOM
	
	"/audio/" =>
	(
		"method" => "basic",
		"realm" => "$model",
		"require" => "valid-user"
	),
	"/dev/" =>
	(
		"method" => "basic",
		"realm" => "$model",
		"require" => "valid-user"
	),
	"/cht/" =>
	(
		"method" => "basic",
		"realm" => "$model",
		"require" => "valid-user"
	),
	"/m/" =>
	(
		"method" => "basic",
		"realm" => "$model",
		"require" => "valid-user"
	),
	"/eng/" =>
	(
		"method" => "basic",
		"realm" => "$model",
		"require" => "valid-user"
	),
	"/cgi/" =>
	(
		"method" => "basic",
		"realm" => "$model",
		"require" => "valid-user"
	),
	"/users/" =>
	(
		"method" => "basic",
		"realm" => "nipca",
		"require" => "valid-user"
	),

EOM
fi
if [ "$model" = "$modelname" ];then
	[ "$DirectAuth" -eq 1 ] && cat << EOM
	"/directview/" =>
	(
		"method" => "basic",
		"realm" => "$model",
		"require" => "valid-user"
	),
	"/video/" =>
	(
		"method" => "basic",
		"realm" => "$model",
		"require" => "valid-user"
	),
EOM
fi
echo ")"
}

writehttpsconf() {
	HttpsPort_num=$(tdb get HTTPServer httpsPort_num)
	[ "$HttpsPort_num" != "" ] || HttpsPort_num=443
	echo "\$SERVER[\"socket\"] == \":$HttpsPort_num\" {"  >> /tmp/lighttpd-inc.conf
	echo '	ssl.engine                  = "enable"'  >> /tmp/lighttpd-inc.conf
	echo '	ssl.pemfile                 = "/tmp/server.pem"'  >> /tmp/lighttpd-inc.conf
	#echo '	server.document-root        = "/www/servers/www.example.org/secure/"' >> /tmp/lighttpd-inc.conf
	#echo '	server.document-root = env.PREFIX + "/tmp/www/"' >> /tmp/lighttpd-inc.conf
	echo '	server.document-root = env.PREFIX + "/var/www/"' >> /tmp/lighttpd-inc.conf
	echo '}' >> /tmp/lighttpd-inc.conf
}

start() {
	! pids=$(pidof $daemon) || die "$daemon($pids) is already running."
	echo -n "Startting $daemon... "
	[ -x $binary ] || die "$binary is not a valid application"
	export LD_LIBRARY_PATH=$prefix/lib
	export PREFIX=$prefix
	DirectAuth=`tdb get DirectView DirectAuth_byte`
	readAccount
	HttpPort_num=$(tdb get HTTPServer Port_num)
	SSLEnable_b=$(tdb get HTTPS enable_byte)
	model=$( [ $(pibinfo Wireless) -eq 1 ] && tdb get System ModelW_ss || tdb get System Model_ss )
	upnpAuth=$(tdb get UPnP Enable_byte)
	
	# create dynamic conf file.
	[ "$HttpPort_num" != "" ] || HttpPort_num=80
	echo > /tmp/lighttpd-inc.conf
	[ -f "/sbin/ecr_client" ] && \
	echo "server.max-keep-alive-requests = 128" >> /tmp/lighttpd-inc.conf && \
	echo "server.max-keep-alive-idle = 30" >> /tmp/lighttpd-inc.conf && \
	echo "server.max-read-idle = 60" >> /tmp/lighttpd-inc.conf && \
	echo "server.max-write-idle = 360" >> /tmp/lighttpd-inc.conf

	[ -e "/tmp/www" ] && rm -rf /tmp/www
	[ -e "/tmp/www/cgi" ] && rm -rf /tmp/www/cgi
	
	if [ "$SSLEnable_b" = "2" ] ; then
		mkdir -p -m 777 /tmp/www 
		mkdir -p -m 777 /tmp/www/cgi 
		ln -sf /var/www/video /tmp/www/video 
		ln -sf /var/www/audio /tmp/www/audio 
		ln -sf /var/www/common /tmp/www/common 
		ln -sf /var/www/users /tmp/www/users 
		ln -sf /var/www/config /tmp/www/config 
		ln -sf /var/www/cgi/eventstream.cgi /tmp/www/cgi/eventstream.cgi 
		ln -sf /var/www/cgi/web_event.cgi /tmp/www/cgi/web_event.cgi 
		echo 'server.document-root = env.PREFIX + "/tmp/www/"' >> /tmp/lighttpd-inc.conf
		writehttpsconf
	elif [ "$SSLEnable_b" = "1" ] ; then
		echo 'server.document-root = env.PREFIX + "/var/www/"' >> /tmp/lighttpd-inc.conf
		writehttpsconf
	else
		echo 'server.document-root = env.PREFIX + "/var/www/"' >> /tmp/lighttpd-inc.conf
	fi

	echo "server.port = $HttpPort_num" >> /tmp/lighttpd-inc.conf
	setupAuth >> /tmp/lighttpd-inc.conf
	# create dynamic user conf
	setupAdmin "$_AdminUser_ss" "$AdminPasswd_ss"
	[ "$User1_ss" != "" ] && setupUser "$User1_ss" "$Password1_ss"
	[ "$User2_ss" != "" ] && setupUser "$User2_ss" "$Password2_ss"
	[ "$User3_ss" != "" ] && setupUser "$User3_ss" "$Password3_ss"
	[ "$User4_ss" != "" ] && setupUser "$User4_ss" "$Password4_ss"
	[ "$User5_ss" != "" ] && setupUser "$User5_ss" "$Password5_ss"
	[ "$User6_ss" != "" ] && setupUser "$User6_ss" "$Password6_ss"
	[ "$User7_ss" != "" ] && setupUser "$User7_ss" "$Password7_ss"
	[ "$User8_ss" != "" ] && setupUser "$User8_ss" "$Password8_ss"
	[ "$User9_ss" != "" ] && setupUser "$User9_ss" "$Password9_ss"
	[ "$User10_ss" != "" ] && setupUser "$User10_ss" "$Password10_ss"
	[ "$User11_ss" != "" ] && setupUser "$User11_ss" "$Password11_ss"
	[ "$User12_ss" != "" ] && setupUser "$User12_ss" "$Password12_ss"
	[ "$User13_ss" != "" ] && setupUser "$User13_ss" "$Password13_ss"
	[ "$User14_ss" != "" ] && setupUser "$User14_ss" "$Password14_ss"
	[ "$User15_ss" != "" ] && setupUser "$User15_ss" "$Password15_ss"
	[ "$User16_ss" != "" ] && setupUser "$User16_ss" "$Password16_ss"
	[ "$User17_ss" != "" ] && setupUser "$User17_ss" "$Password17_ss"
	[ "$User18_ss" != "" ] && setupUser "$User18_ss" "$Password18_ss"
	[ "$User19_ss" != "" ] && setupUser "$User19_ss" "$Password19_ss"
	[ "$User20_ss" != "" ] && setupUser "$User20_ss" "$Password20_ss"
	# start...
	$binary -f $prefix/etc/lighttpd/lighttpd.conf -m $prefix/lib
	echo "ok."
	#[ "$SSLEnable_b" = "1" -o "$SSLEnable_b" = "2" ] && $prefix/etc/rc.d/init.d/lighttpd_ssl.sh start
}

status() {
	echo -n "$daemon"
	pids=$(pidof $daemon) && echo "($pids) is running." || echo " is stop."
	#SSLEnable_b=$(tdb get HTTPS enable_byte)
	#[ "$SSLEnable_b" = "1" -o "$SSLEnable_b" = "2" ] && $prefix/etc/rc.d/init.d/lighttpd_ssl.sh status
}

stop() {
	pids=$(pidof $daemon) || { echo "$daemon is not running." && return 1; }
	echo -n "Stopping $daemon... "
	kill $(echo $pids | cut -d' ' -f1)
	sleep 1
	pids=$(pidof $daemon) && killall -9 $daemon && sleep 1 && pids=$(pidof $daemon) && die "ng." || echo "ok."
	#/etc/rc.d/init.d/lighttpd_ssl.sh stop
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
		stop
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
