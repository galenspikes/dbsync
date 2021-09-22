#!/bin/bash

############################################################################
# SET DBSYNC CONFIG FILE (full path)
############################################################################
# 
  DBSYNC_CONFIG_FILE=dbsync.conf
#
############################################################################
############################################################################

# check if config exists or else exit
if test -f ${DBSYNC_CONFIG_FILE}; then
  echo "config exists, continue"
  source ${DBSYNC_CONFIG_FILE}
else
  echo "ERROR: config does not exist, please create or configure properly"
  exit
fi

function usage() {
  echo "
  --source-host (required)
  --target-host (required)
  --source-db (source database name -- required)
  --target-db (target database name -- required)
  --conn-type (mysql, postgresql, or mongodb -- required)
  --threads (integer -- required)

  -h|--help

  Example Command:
  
  ./dbsync.sh --source-host myserver1.com --target-host myserver2.com --source-db dev_baseball --target-db prod_football --conn-type postgresql --threads 8 &
  "
}

while [[ "$1" == --* ]]; do
  case "$1" in
  --source-host)
    shift
    source_host="$1"
    ;;
  --target-host)
    shift
    target_host="$1"
    ;;
  --source-db)
    shift
    source_db="$1"
    ;;
  --target-db)
    shift
    target_db="$1"
    ;;
  --conn-type)
    shift
    conn_type="$1"
    ;;
  --threads)
    shift
    threads="$1"
    ;;
  -h|--help)
    usage
    exit 0
    ;;
  --)
    shift
    break
    ;;
  esac
  shift
done
shift $(( OPTIND - 1 ))

echo "Syncing ${conn_type} - ${database_name}"

if [ ${conn_type} = "mysql" ]; then
    ${working_directory}/modules/dbsync_mysql.sh --source-host ${source_host} --target-host ${target_host} --source-db ${source_db} --target-db ${target_db} --threads ${threads} --config ${DBSYNC_CONFIG_FILE}
elif [ ${conn_type} = "postgresql" ]; then
  home_dir=`echo ~`
  if test -f "${home_dir}/.pgpass"; then
    echo ".pgpass exists, continue."
    if grep -q ${app_user} "${home_dir}/.pgpass"; then
      echo "${app_user} entry found in .pgpass, continue"
    else
      echo "ERROR: ${app_user} entry not found in .pgpass. Please configure properly"
      echo "Documentation: https://www.postgresql.org/docs/12/libpq-pgpass.html"
      exit
    fi
  else
    echo "ERROR: .pgpass does not exist. Please create and configure."
    echo "Documentation: https://www.postgresql.org/docs/12/libpq-pgpass.html"
    exit
  fi
  ${working_directory}/modules/dbsync_postgresql.sh --source-host ${source_host} --target-host ${target_host} --source-db ${source_db} --target-db ${target_db} --threads ${threads} --config ${DBSYNC_CONFIG_FILE}
elif [ ${conn_type} = "mongodb" ]; then
  ${working_directory}/modules/dbsync_mongodb.sh --source-host ${source_host} --target-host ${target_host} --source-db ${source_db} --target-db ${target_db} --threads ${threads} --config ${DBSYNC_CONFIG_FILE}
else
  echo "ERROR: Something is wrong with how you entered the command. Don't forget any of the parameters"
  usage
fi

