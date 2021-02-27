#!/bin/bash
# author: tierrie
# date: 20201128
# synopsis: script joins the ubuntu machine (20.04 LTS) and joins it to an 
#           active directory domain, allowing domain logins and sudoers
#           tied to domain groups
# credits: instructions provided manually from 
#           https://computingforgeeks.com/join-ubuntu-debian-to-active-directory-ad-domain/


# set this to make it fully automated (prompting for password occurs up front)
FULLY_AUTOMATED=1

# check that sudo is run
if [ `id -u` -ne 0 ]; then
	echo Need sudo
	exit 1
fi

unset CONFIRM
while [[ -z $CONFIRM || $CONFIRM != "y" ]]; do
	read -p "Specify the hostname of this machine: " HOSTNAME
	read -p "Set hostname to ${HOSTNAME}. Is this correct (y/n)? " CONFIRM
done

unset CONFIRM
while [[ -z $CONFIRM || $CONFIRM != "y" ]]; do
	read -p "Specify the domain you want to join: " DOMAIN
	read -p "Joining the domain ${DOMAIN}. Is this correct (y/n)? " CONFIRM
done

# this prompts for password and echos it to the realm join, but could be a security risk
# need to think about this.
if [ ! -z $FULLY_AUTOMATED ]; then
	unset CONFIRM 
	unset PASSWORD 
	while [[ -z $CONFIRM || -z $PASSWORD || $CONFIRM != $PASSWORD ]]; do 
		read -p "Enter an account with privileges to join to $DOMAIN: " USER 
		read -s -p "Enter the password for $USER: " PASSWORD 
		echo "" 
		read -s -p "Confirm the password for $USER: " CONFIRM 
		echo "" 
		if [ $CONFIRM != $PASSWORD ]; then 
			echo "Passwords do not match." 
			unset PASSWORD 
			unset CONFIRM 
		fi
	done
else
	read -p "Enter an account with privileges to join $DOMAIN: " USER
fi

# use fully qualified user name
while [[ -z $USE_UPN || ! ($USE_UPN == "y" || $USE_UPN == "n") ]]; do
	read -p "Would you like to use User Principal Name with the Domain Name as the suffix during login (e.g. username@domain.local) (y/n)? " USE_UPN
done


# print out lines as they are read
set -v

# update apt-cache
apt update -y
apt upgrade -y

# update apt index
tee -a /etc/apt/sources.list <<EOF
deb http://us.archive.ubuntu.com/ubuntu/ bionic universe
deb http://us.archive.ubuntu.com/ubuntu/ bionic-updates universe
EOF

# install required packages
sudo apt -y install realmd libnss-sss libpam-sss sssd sssd-tools adcli samba-common-bin oddjob oddjob-mkhomedir packagekit

# set the hostname
hostnamectl set-hostname "${HOSTNAME}.${DOMAIN}"
echo "Hostname set"

# display hostname
hostnamectl

# disable systemd-resolve - unsure about this code.. why does it need to be disabled?
#systemctl disable systemd-resolved
#systemctl stop systemd-resolved

# create domain variables
DISTRO=`hostnamectl | grep "Operating System" | cut -d":" -f2 | sed 's/^\s*//g'`
KERNEL=`uname -rsv`


# join the system to the domain - if the password was prompted earlier, auto fill it
if [[ -z $FULLY_AUTOMATED || -z $PASSWORD ]]; then
	realm join $DOMAIN --verbose --user="$USER" --os-name="$DISTRO" --os-version="$KERNEL"
else
	echo $PASSWORD | realm join $DOMAIN --verbose --user="$USER" --os-name="$DISTRO" --os-version="$KERNEL"
fi

# enable auto creation of home directory
cat > /usr/share/pam-configs/mkhomedir <<EOF
Name: activate mkhomedir
Default: yes
Priority: 900
Session-Type: Additional
Session:
				required                        pam_mkhomedir.so umask=0022 skel=/etc/skel
EOF

# enable it
# can check it with pam-auth-update and verify that mkhomedir has an asterisk * next to it
pam-auth-update --enable mkhomedir

# enable the ability to allow domain users to log in with ssh
realm permit -g "Domain Users"

# modify the sudoers file to allow domain admins to log in
if [[ -z $USE_UPN || $USE_UPN == "y" ]]; then
	# only allow UPN to be super users e.g. username@domain.local 
	cat > /etc/sudoers.d/domain_admin <<- EOF
		%Domain\ Admins@$DOMAIN ALL=(ALL) ALL
	EOF
else
	# removes the need to use fully qualified login names e.g. username@domain.local and allow logins with just username
	sed -i -e 's/use_fully_qualified_names = True/use_fully_qualified_names = False/g' /etc/sssd/sssd.conf

	# removes the home directory from /home/username@domain.local and just places it in /home
	sed -i -e s'/fallback_homedir = \/home\/%u@%d/fallback_homedir = \/home\/%u/g' /etc/sssd/sssd.conf

	# allow users in the Domain Admins group without logging in with UPN e.g. username
	cat > /etc/sudoers.d/domain_admin <<- EOF
		%Domain\ Admins ALL=(ALL) ALL
	EOF
fi

# restart sssd
systemctl restart sssd
systemctl status sssd.service
