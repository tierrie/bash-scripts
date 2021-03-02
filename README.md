# linux-scripts


A collection of scripts that is meant to make life easier.

prepare-ubuntu-20.04-02-template.sh - Assumes a fresh install of Ubuntu 20.04. Patches. Deletes all the unique ids, hostnames, and prepares the machine to be templatized.

join-ubuntu-to-domain.sh - Assumes a fresh install of Ubuntu 20.04 LTS and joins the machine to MS Active Directory. This allows users to log in with domain credentials. Uses AD groups for permissions including sudo.

update-ntp-to-domain.sh - Updates NTP, sets timezones, starts NTP

download-minecraft-server-binaries.py - Downloads the latest minecraft server binaries into /opt/minecraft/server_binaries. Creates a symbolic link /opt/minecraft/instances/<world>/minecraft_servar.jar to this file.
