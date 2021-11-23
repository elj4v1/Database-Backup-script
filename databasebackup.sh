#!/bin/bash
# Shell script to backup docker container with MYQSL/mariaDB
#
# Script to make backup copies of a mysql / mariadb database that is hosted in a docker container.
# This script allows to ignore the databases that we do not want to save in the backup copy by adding it to the DBSKIPLIST list.
#
# Author: Javi.
#         https://github.com/elj4v1
# @2021

# Set variables
MyUSER="DB_USER" # Database user
MyPASS="DB_PASSORD" # Database password
DockerCNAME="CONTAINER_NAME" # Name of database docker container
DockerHOST="$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $DockerCNAME)" # Get database docker container IP
MyHOST=$DockerHOST # Database Hostname (If not use a docker container, set IP or hostname here)
MYSQL_CHECK_USER="CHECK_USER" # Readonly user used for check database connection (user & password)

# Linux bin paths
MYSQL="$(which mysql)"
MYSQLDUMP="$(which mysqldump)"
MYSQLADMIN="$(which mysqladmin)"
GZIP="$(which gzip)"

# Get date formats
NOW="$(date +%d%m%Y_%H%M%S)"
MONTH="$(date +%m-%b)"
YEAR="$(date +%Y)"
LASTMONTH="$(date +%m-%b -d 'last month')"
LASTYEAR="$(date +%Y -d 'last year')"

# Backup directory
BKPDBDIR="/backup/mariadb" # Path of backup database directory
[ ! -d $BKPDBDIR ] && mkdir -p $BKPDBDIR || :

# Log directory
LOGDIR="/backup/logs/database/$YEAR/$MONTH/" # Path of backup database log file
[ ! -d $LOGDIR ] && mkdir -p $LOGDIR || :

# Backup sub-directories
BKPSUBDIR="$BKPDBDIR/$YEAR/$MONTH/$NOW/mysql"

# Get all databases
DBSHOW="$($MYSQL -h $MyHOST -u $MyUSER -p$MyPASS -Bse 'show databases')"

# Database skip list
DBSKIPLIST="information_schema
performance_schema
mysql
sys"

# Check MYSQL server connection
function mysqlconnectionstatus {
    $MYSQLADMIN ping -h $MyHOST -u $MYSQL_CHECK_USER -p${MYSQL_CHECK_USER} 2>/dev/null 1>/dev/null
    [ ${?} == "0" ] && return 0 || return 1
}

# Database dumps
function mysqldumpdatabase (){
    $MYSQLDUMP --force --opt -h $MyHOST -u $MyUSER -p$MyPASS --databases $1 > $2 2>/dev/null 1>/dev/null
}

 # Compress the directory
function compressNow {
    cd "$BKPDBDIR/$YEAR/$MONTH"
    tar -cf $NOW.tar $NOW
    $GZIP -9 $NOW.tar
    rm -rf $NOW
}

 # Compress the last month directory
function compressLastmonth {
    cd "$BKPDBDIR/$YEAR/"
    tar -cf $LASTMONTH.tar $LASTMONTH
    $GZIP -9 $LASTMONTH.tar
    rm -rf $LASTMONTH
}

 # Compress the last year directory
function compressLastyear {
    cd "$BKPDBDIR"
    tar -cf $LASTYEAR.tar $LASTYEAR
    $GZIP -9 $LASTYEAR.tar
    rm -rf $LASTYEAR
}

# Compress directory function
function archivedirectory {
    compressNow
    [ -d "$BKPDBDIR/$YEAR/$LASTMONTH" ] && compressLastmonth || :
    [ -d "$BKPDBDIR/$LASTYEAR" ] && compressLastyear || :
}

# Main
mysqlconnectionstatus
if [ ${?} -eq 0 ]; then
    #Create Backup sub-directories
    install -d $BKPSUBDIR
    # Database skip list
    for db in $DBSHOW
    do
        skipdatabase=-1
        if [ "DBSKIPLIST" != "" ];
        then
            for i in $DBSKIPLIST
            do
               [ "$db" == "$i" ] && skipdatabase="1" || :
            done
         fi
         if [ "$skipdatabase" == "-1" ] ; then
            FILE="$BKPSUBDIR/$db.sql"
            # Database dump
            mysqldumpdatabase $db $FILE
            if [ ${?} -eq 0 ]; then
                echo "$NOW: $db database backup was successful. File:$FILE" >> "$LOGDIR/$MONTH.log" #Save the successful message on the log file
                echo "$NOW: Backup was successful. File:$FILE" # Shows the successful message on the screen (Valid for a cron log record)
            else
                echo "$NOW: An error occurred while $db database backing up" >> "$LOGDIR/$MONTH.log" # Save the error message on the log file
                echo "$NOW: An error occurred while $db database backing up" # Shows the error message on the screen (Valid for a cron log record)
            fi
        fi
     done
     # Archive the directory
     archivedirectory
else
    echo "The connection to the $MyHOST database host could not be established" # Shows the connection error message on the screen (Valid for a cron log record)
fi
