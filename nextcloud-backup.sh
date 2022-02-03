#!/bin/bash

# This script saves and rotate important Nextcloud data
# to the BACKUP_DIR directory.
#
# This script is designed to be ran by a cron service.
# It is recommended to put the script in /etc/cron.daily/ as an executable

logger -p cron.debug "$0: Nextcloud backup started."

# SET THOSE TWO
NEXTCLOUD_DIR=
BACKUP_DIR=
MAX_BACKUPS=3
BACKUP_COUNT=$(ls -1 $BACKUP_DIR | wc -l) # Don't change

# Exits the program if either the current dir or the backup dir does not exist.
if [ ! -d $NEXTCLOUD_DIR ] || [ ! -d $BACKUP_DIR ]
then
    ERROR="$0: No Nextcloud or backup directory specified. Verify the script's variables."

    logger -p cron.warn $ERROR
    echo $ERROR 1>&2

    exit 1
fi

# Rotates the backups in BACKUP_DIR to keep a maximum of MAX_BACKUPS
rotate ()
{
    # How many backups to remove
    TO_DELETE=$[$BACKUP_COUNT-$MAX_BACKUPS]

    for bak in $(ls -1 $BACKUP_DIR | head -n $TO_DELETE)
    do
	logger -p cron.notice "$0: Rotating $BACKUP_DIR/$bak."
	rm -rf $BACKUP_DIR/$bak
    done
    return 0
}

# Creates a backup of NEXTCLOUD_DIR into BACKUP_DIR
backup ()
{
    # Naming scheme: 'nextcloud-YEAR-MONTH-DAY.VERSION'
    VERSION=1
    NEW_BACKUP=$BACKUP_DIR/nextcloud-$(date +%F).$VERSION

    # Increments the version until unique, backs up, and then exits
    while [ true ]
    do
	if [ ! -e $NEW_BACKUP.tar.gz ]
	then
	    mkdir -p $NEW_BACKUP
	    cp -a $NEXTCLOUD_DIR/data $NEXTCLOUD_DIR/config $NEW_BACKUP
	    tar -czf $NEW_BACKUP.tar.gz $NEW_BACKUP
	    rm -rf $NEW_BACKUP
	    
	    logger -p cron.debug "$0: $NEXTCLOUD_DIR backed up in $NEW_BACKUP."

	    BACKUP_COUNT=$[$BACKUP_COUNT + 1]
	    
	    return 0
	else
	    # Adds "(x) at the end of the backup
	    # 'x' representing the number of backup done this day
	    VERSION=$[$VERSION + 1]
	    NEW_BACKUP=$BACKUP_DIR/nextcloud-$(date +%F).$VERSION
	fi
    done
}

backup

if [ $BACKUP_COUNT -gt $MAX_BACKUPS ]
then
    rotate
fi

logger -p cron.debug "$0: Nextcloud backup ended with success."
exit 0
