#!/bin/sh

SD_DIR=/dev/scsi/host0/bus0/target0/lun0
SD_DEV=$SD_DIR/part1
SD_MNT_DIR=/mnt/usb
SD_MNT_TMP_DIR=/tmp/usb
SD_MNT_FIL=/tmp/sd_mnt
SD_TMP_FIL=$SD_MNT_TMP_DIR/.sd_syn_file

#loop for check sd card
while :
do
	#check sd card
	SD_DISC=`ls $SD_DIR | grep "part1"`
	if [ "$SD_DISC" = "part1" ]
	#check mount sd card to /tmp/usb
	then
		mkdir -p $SD_MNT_TMP_DIR >>/dev/null 2>&1
		SD_MNTED=`mount | grep "$SD_DIR/part1" | grep "$SD_MNT_TMP_DIR" | cut -d' ' -f3`
		if [ "$SD_MNTED" = "$SD_MNT_TMP_DIR" ]
		then
			#umount /tmp/usb first
			umount $SD_MNT_TMP_DIR >>/dev/null 2>&1
			if [ "$?" -eq "0" ]
			#mount to /tmp/usb again
			then
				mount -t vfat -w $SD_DEV $SD_MNT_TMP_DIR >>/dev/null 2>&1
				if [ "$?" -eq "0" ]
				then
					#mkdir $SD_TMP_FIL >>/dev/null 2>&1
					touch $SD_TMP_FIL >>/dev/null 2>&1
					if [ "$?" -eq "0" ]
					then
						#mount rw to /mnt/usb
						rm -f $SD_TMP_FIL
						SD_MNTED=`mount | grep "$SD_DIR/part1" | grep "$SD_MNT_DIR" | cut -d' ' -f3`
						if [ "$SD_MNTED" = "$SD_MNT_DIR" ]
						then
							echo "1" > $SD_MNT_FIL
						else
							mount -t vfat -w $SD_DEV $SD_MNT_DIR >>/dev/null 2>&1
							if [ "$?" -eq "0" ]
							then
								echo "1" > $SD_MNT_FIL
							else
								echo "0" > $SD_MNT_FIL
							fi
						fi	
					else
						#mount ro to /mnt/usb
						SD_MNTED=`mount | grep "$SD_DIR/part1" | grep "$SD_MNT_DIR" | cut -d' ' -f3`
						if [ "$SD_MNTED" = "$SD_MNT_DIR" ]
						then
							echo "2" > $SD_MNT_FIL
						else	
							mount -t vfat -w $SD_DEV $SD_MNT_DIR >>/dev/null 2>&1
							if [ "$?" -eq "0" ]
							then
								echo "2" > $SD_MNT_FIL
							else
								echo "0" > $SD_MNT_FIL
							fi
						fi
					fi
					#umount /tmp/usb
					umount $SD_MNT_TMP_DIR
				else
					echo "0" > $SD_MNT_FIL
					SD_MNTED=`mount | grep "$SD_DIR/part1" | grep "$SD_MNT_DIR" | cut -d' ' -f3`
					if [ "$SD_MNTED" = "$SD_MNT_DIR" ]
					then
						umount $SD_MNT_DIR >>/dev/null 2>&1
					fi
				fi
			#umount /mnt/usb
			else
				echo "0" > $SD_MNT_FIL
				SD_MNTED=`mount | grep "$SD_DIR/part1" | grep "$SD_MNT_DIR" | cut -d' ' -f3`
				if [ "$SD_MNTED" = "$SD_MNT_DIR" ]
				then
					umount $SD_MNT_DIR >>/dev/null 2>&1
				fi
			fi
		else
			#mount to /tmp/usb
			mount -t vfat -w $SD_DEV $SD_MNT_TMP_DIR >>/dev/null 2>&1
			if [ "$?" -eq "0" ]
			then
				#check touch file in /tmp/usb
				#mkdir $SD_TMP_FIL >>/dev/null 2>&1
				touch $SD_TMP_FIL >>/dev/null 2>&1
				if [ "$?" -eq "0" ]
				then
					#mount rw to /mnt/usb
					rm -f $SD_TMP_FIL
					SD_MNTED=`mount | grep "$SD_DIR/part1" | grep "$SD_MNT_DIR" | cut -d' ' -f3`
					if [ "$SD_MNTED" = "$SD_MNT_DIR" ]
					then
						echo "1" > $SD_MNT_FIL
					else
						mount -t vfat -w $SD_DEV $SD_MNT_DIR >>/dev/null 2>&1
						if [ "$?" -eq "0" ]
						then
							echo "1" > $SD_MNT_FIL
						else
							echo "0" > $SD_MNT_FIL
						fi
					fi	
				else
					#mount ro to /mnt/usb
					SD_MNTED=`mount | grep "$SD_DIR/part1" | grep "$SD_MNT_DIR" | cut -d' ' -f3`
					if [ "$SD_MNTED" = "$SD_MNT_DIR" ]
					then
						echo "2" > $SD_MNT_FIL
					else	
						mount -t vfat -w $SD_DEV $SD_MNT_DIR >>/dev/null 2>&1
						if [ "$?" -eq "0" ]
						then
							echo "2" > $SD_MNT_FIL
						else
							echo "0" > $SD_MNT_FIL
						fi
					fi
				fi
				#umount /tmp/usb
				umount $SD_MNT_TMP_DIR
			#umount /mnt/usb
			else
				echo "0" > $SD_MNT_FIL
				SD_MNTED=`mount | grep "$SD_DIR/part1" | grep "$SD_MNT_DIR" | cut -d' ' -f3`
				if [ "$SD_MNTED" = "$SD_MNT_DIR" ]
				then
					umount $SD_MNT_DIR >>/dev/null 2>&1
				fi
			fi
		fi
	#umount sd card
	else
		echo "0" > $SD_MNT_FIL
		#umount /mnt/usb
		SD_MNTED=`mount | grep "$SD_DIR/part1" | grep "$SD_MNT_DIR" | cut -d' ' -f3`
		if [ "$SD_MNTED" = "$SD_MNT_DIR" ]
		then
			umount $SD_MNT_DIR >>/dev/null 2>&1
		fi
		#umount /tmp/usb
		SD_MNTED=`mount | grep "$SD_DIR/part1" | grep "$SD_MNT_TMP_DIR" | cut -d' ' -f3`
		if [ "$SD_MNTED" = "$SD_MNT_TMP_DIR" ]
		then
			umount $SD_MNT_TMP_DIR >>/dev/null 2>&1
		fi
	fi
	#sleep 5 seconds
	sleep 5
done
