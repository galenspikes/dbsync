#!/bin/bash

date=`date +%Y%m%d_%Hh%Mm%Ss`
uuid=`date +%N%s`
tmpdir=tmp_dbsync_${uuid}

function usage() {
  echo "  
  --source-host
  --target-host
  --source-db
  --target-db
  -h|--help
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
  --threads)
    shift
    threads="$1"
    ;;
  --config)
    shift
    dbsync_config_file="$1"
    ;;
  esac
  shift
done
shift $(( OPTIND - 1 ))

source ${dbsync_config_file}

echo ""
echo ""
echo "---------------------------------------------------------------------------------"
echo "------------------------- DBSYNC ------------------------------------------------"
echo "---------------------------------------------------------------------------------"
echo "`date "+%D %T"`: Runtime: `date`"
echo "`date "+%D %T"`: Download Path: ${DOWNLOAD_PATH}"
echo "`date "+%D %T"`: Source Host: ${source_host}"
echo "`date "+%D %T"`: Target Host: ${target_host}"
echo "`date "+%D %D"`: Database Name: ${database_name}"
echo "`date "+%D %T"`: Source Environment Prefix: ${source_db}"
echo "`date "+%D %T"`: Target Environment Prefix: ${target_db}"
echo "`date "+%D %T"`: Datetime: ${date}"
echo "`date "+%D %T"`: Number of Threads: ${threads}"

echo "`date "+%D %T"`: Downloading ${source_db} from ${source_host}"

###############
# Dump step
###############
time mydumper --host ${source_host} -u ${app_user} -p "${app_user_password}" -v 3 --use-savepoints --no-locks --long-query-guard=${long_query_guard_val} -B ${source_db} -o ${download_path}/${tmpdir} --threads ${threads} --routines --events --triggers --no-views

echo "`date "+%D %T"`: Finished downloading ${source_db}"

################
# Load step
################
echo "`date "+%D %T"`: Loading ${source_host} data into ${target_host}"

myloader -o -h ${target_host} -u ${app_user} -p "${app_user_password}" -B tmp1_${target_db} -d ${download_path}/${tmpdir} -v 3 --threads ${threads}

# Get count of views from source_db
declare -i source_db_num_views=`mysql -h ${source_host} -u ${app_user} --password="${app_user_password}" --skip-column-names --batch -e "select count(table_name) from tables where table_type = 'VIEW' and table_schema = '${source_db}'" information_schema`

# Dump views from source_db
mysql -h ${source_host} -u ${app_user} --password="${app_user_password}" --skip-column-names --batch -e "select table_name from tables where table_type = 'VIEW' and table_schema = '${source_db}'" information_schema | xargs mysqldump -h ${target_host} -u ${app_user} --password="${app_user_password}" ${source_db} > ${download_path}/${tmpdir}/views.sql
# Scrub references to oldSchemaName, change to newSchemaName
sed -i "s/${oldSchemaName}/${newSchemaName}/g" "${download_path}/${tmpdir}/views.sql"

echo Load views
declare -i target_db_num_views=0
while [ ${target_db_num_views} -le ${source_db_num_views} ]; 
do
  if [[ ${target_db_num_views} -lt ${source_db_num_views} ]]; then 
    mysql -s -f -h ${target_host} -u ${app_user} --password="${app_user_password}" tmp1_${target_db} < ${download_path}/${tmpdir}/views.sql
    declare -i target_db_num_views=`mysql -h ${target_host} -u ${app_user} --password="${app_user_password}" --skip-column-names --batch -e "select count(table_name) from tables where table_type = 'VIEW' and table_schema = 'tmp1_${target_db}'" information_schema`
    echo "target_db_num_views: $target_db_num_views"
    echo "source_db_num_views: $source_db_num_views"
  elif [[ ${target_db_num_views} -eq ${source_db_num_views} ]]; then
    echo "target_db_num_views: $target_db_num_views"
    echo "source_db_num_views: $source_db_num_views"
    break
  fi
done

################
# Swap step
################
echo "`date "+%D %T"`: Swap in new data"
mysql -v -h ${target_host} -u ${app_user} --password="${app_user_password}" -e "create database if not exists ${target_db}" information_schema
sh ${mysql_db_rename_path}/mysql_db_rename.sh ${target_db} tmp2_${target_db} ${target_host} ${app_user} "${app_user_password}"
sh ${mysql_db_rename_path}/mysql_db_rename.sh tmp1_${target_db} ${target_db} ${target_host} ${app_user} "${app_user_password}"
mysql -v -h ${target_host} -u ${app_user} --password="${app_user_password}" -e "drop database if exists tmp1_${target_db}; drop database if exists tmp2_${target_db};" information_schema
echo "`date "+%D %T"`: Deleting temp files..."
rm -rf ${download_path}/${tmpdir}

echo "`date "+%D %T"`: Done!"
