#!/bin/sh
SD_DEV=/dev/scsi/host0/bus0/target0/lun0/disc
SD_PART1=/dev/scsi/host0/bus0/target0/lun0/part1
SD_MNT_DIR=/mnt/usb

##check if record enable and record to sd card
echo -n "check record... "
RECORD_ENABLE=`tdb get Record Enable_byte`
echo "record_enable = $RECORD_ENABLE"

if [ "$RECORD_ENABLE" -eq "1" ]
then
	RECORD_USB=`tdb get USB Enable_byte`
	echo "usb_enable = $RECORD_USB"
	if [ "$RECORD_USB" -eq "1" ]
	then
		echo "record to usb is stopping"
		/etc/rc.d/init.d/recorderd.sh stop >> /dev/null 2>&1
	fi
fi

##stop watchDog_usb
/etc/rc.d/init.d/watchDog_usb.sh stop


##umount sd card
SD_MNTED=`mount | grep "$SD_PART1" | grep "$SD_MNT_DIR" | cut -d' ' -f3`
if [ "$SD_MNTED" = "$SD_MNT_DIR" ];then
	echo -n "umount sdcard... "
	umount $SD_MNT_DIR >>/dev/null 2>&1
	if [ "$?" -eq "1" ];then
		echo "error."
		/etc/rc.d/init.d/watchDog_usb.sh start
		return 1
	else
		echo "ok."
	fi
fi

##create partition 1 if it is not exist.
PART1_INFO=`fdisk -l $SD_DEV | grep  $SD_PART1`
if [ -z "$PART1_INFO" ];then 
	echo "No partition 1 in SD card, create it..."
	(echo -e "n\np\n1\n\n\nw\n" | fdisk $SD_DEV) >>/dev/null 2>&1
	echo -n "create partition 1: "
	PART1_INFO=`fdisk -l $SD_DEV | grep  $SD_PART1`
	if [ -z "$PART1_INFO" ];then 
		echo "failure, maybe no free sectors available."
		/etc/rc.d/init.d/watchDog_usb.sh start
		return 1
	else
		echo "ok."
	fi
fi

PART1_SIZE=`fdisk -s $SD_PART1`
#echo "$PART1_SIZE"
if [ "$PART1_SIZE" -gt "16777216" ];then
	echo "recreate partition 1..."
	NUM_P=`fdisk -l $SD_DEV | grep -c "/dev/scsi/host0/bus0/target0/lun0/part"`
  #echo "$NUM_P"
  if [ "$NUM_P" -gt "0" ];then
  	(echo -e "d\n1\nn\np\n1\n\n+16G\nt\n1\nb\nw\n" | fdisk $SD_DEV) >>/dev/null 2>&1
  else
    (echo -e "d\nn\np\n1\n\n+16G\nt\nb\nw\n" | fdisk $SD_DEV) >>/dev/null 2>&1
  fi
fi	

##format sd card
echo -n "format sd card... "

##SECTORS: sectors-per-cluster
if [ $PART1_SIZE -gt 32768 ]
then
	SECTORS=1
	if [ $PART1_SIZE -gt 4194304 ];then
		SECTORS=128
	elif [ $PART1_SIZE -gt 2097152 ];then
		SECTORS=64
	elif [ $PART1_SIZE -gt 1048576 ];then
		SECTORS=32
	elif [ $PART1_SIZE -gt 524288 ];then
		SECTORS=16	
	elif [ $PART1_SIZE -gt 262144 ];then
		SECTORS=8
	elif [ $PART1_SIZE -gt 131072 ];then
		SECTORS=4
	elif [ $PART1_SIZE -gt 65536 ];then
		SECTORS=2	
	fi
	#echo "$SECTORS"
	##block_size=SECTORS*512/1024
	mkdosfs -F 32 -s $SECTORS -S 512 $SD_PART1 >>/dev/null 2>&1
else
	##fat16
	mkdosfs $SD_PART1 >>/dev/null 2>&1
fi

if [ "$?" -eq "1" ];then
	echo "failure"
	/etc/rc.d/init.d/watchDog_usb.sh start
	return 1
else
	echo "ok"
	/etc/rc.d/init.d/watchDog_usb.sh start
fi

if [ "$RECORD_ENABLE" -eq "1" ]
then
	RECORD_USB=`tdb get USB Enable_byte`
	#echo "usb_enable = $RECORD_USB"
	if [ "$RECORD_USB" -eq "1" ]
	then
		echo "record to usb is starting"
		(/etc/rc.d/init.d/recorderd.sh restart >> /dev/null 2>&1) &
	fi
fi

sleep 5


	
