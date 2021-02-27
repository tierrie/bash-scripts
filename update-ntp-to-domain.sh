#!/bin/bash
# author: tierrie
# date: 20200227
# synopsis: script updates the ubuntu machine to use ntp, and sets the timezone

# check that sudo is run
if [ `id -u` -ne 0 ]; then
	echo Need sudo
	exit 1
fi

unset CONFIRM
unset NTPSERVER
while [[ -z $NTPSERVER || -z $CONFIRM || $CONFIRM != "y" ]]; do
	read -p "Specify the NTP servers (comma separated with no spaces): " NTPSERVER
	read -p "NTP servers set to ${NTPSERVER}. Is this correct (y/n)? " CONFIRM
done

unset CONFIRM
TIMEZONE="America/Los Angeles"
while [[ -z $TIMEZONE || -z $CONFIRM || $CONFIRM != "y" ]]; do
	read -p "Specify the timezone (default: ${TIMEZONE}): " TIMEZONE
	TIMEZONE="${TIMEZONE:-America/Los Angeles}"
	read -p "Timezone set to ${TIMEZONE}. Is this correct (y/n)? " CONFIRM
done



# removes the home directory from /home/username@domain.local and just places it in /home
sed -i -e s"|^#\?NTP.\+|NTP=${NTPSERVER}|g" /etc/systemd/timesyncd.conf

# enable ntp
timedatectl set-ntp true

# restart the ntp sync service
systemctl restart systemd-timesyncd.service

# validate that it is running
timedatectl show-timesync --all
timedatectl status