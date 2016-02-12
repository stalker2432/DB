#!/bin/bash

pass=""
db=""
dbsource=""
dbuser=root
pathdb="/var/lib/mysql"
dbsch="schema_new.sql"

if [ "$#" -eq  "0" ]
   then
     echo "No params is set!"
    exit 1
fi

while [[ $# > 1 ]]
do
key="$1"

case $key in
    -dbd|--dbdestination)
    db="$2"
    shift # past argument
    ;;
    -dbs|--dbsource)
    dbsource="$2"
    shift # past argument
    ;;
    -dbu|--dbuser)
    dbuser="$2"
    shift # past argument
    ;;
    -dbp|--dbpass)
    pass="$2"
    shift # past argument
    ;;
    -dba|--dbschema)
    dbsch="$2"
    shift # past argument
    ;;
    -dbh|--dbhost)
    dbh="$2"
    shift # past argument
    ;;
    --default)
    DEFAULT=YES
    ;;
    *)
            # unknown option
    ;;
esac
shift # past argument or value
done

        echo "Source database is: $dbsource"
	echo "Destination database is: $db"
	echo "Path to schema file is: $dbsch"
	echo "DBuser is: $dbuser"
	echo "DBpass is: $pass"

read -r -p "Are you sure? [y/N] " response
if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]
then
    Strting...
else
    exit 1
fi


if [ -f $dbsch ];
then
   echo "File $FILE exists."
else
   echo "File $FILE does not exist... getting schema from origin db"
    mysqldump -u$dbuser  -p$pass --no-data $dbsource > $dbsch
fi



if [[ $USER != "mysql" ]]; then 
	echo "This script must be run as mysql user!" 
	exit 1
    fi 



echo "1) drop database"
echo "drop database $db;" | mysql -u$dbuser -p$pass

echo "2) create empty database"
echo "create database $db;" | mysql -u$dbuser -p$pass

echo "3) create structure database"
mysql -u$dbuser -p$pass -D $db < ./$dbsch

echo "4) get list of tables"
res2=`mysql --user=$dbuser --password=$pass --skip-column-names -e "use $db;show tables"`
items=$(echo $res2 | tr " " "\n")

echo "5) DISCARD tables space by list"
for item in $items
do
echo "alter table $db.$item DISCARD tablespace;"
echo "set FOREIGN_KEY_CHECKS=0; alter table $db.$item DISCARD tablespace;" | mysql -u$dbuser -p$pass $db
done


echo "6) copy *.ibd files from origin"
cp $pathdb/$dbsource/*.ibd $pathdb/$db/

echo "7) Import tables space by list"
for item in $items
do
echo "alter table $db.$item IMPORT tablespace;"
echo "set FOREIGN_KEY_CHECKS=0; alter table $db.$item IMPORT tablespace;" | mysql -u$dbuser -p$pass $db
done
