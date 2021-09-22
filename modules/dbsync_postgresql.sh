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

source ${dbsync_config_file}

tmp1_target_db=tmp1_${target_db}
tmp2_target_db=tmp2_${target_db}

echo ${source_host}
echo ${tmpdir}
echo ${threads}
pg_dump --verbose --host=${source_host} --username=${app_user} -Z 3 -j ${threads} --format=d -f ${download_path}/${tmpdir} -d ${source_db}

echo "`date "+%D %T"`: Finished downloading ${source_db}"

psql -h ${target_host} -U ${app_user} -c "select pg_terminate_backend(pid) from pg_stat_activity where datname='${tmp1_target_db}'" postgres
psql -h ${target_host} -U ${app_user} -c "drop database if exists ${tmp1_target_db}" postgres
psql -h ${target_host} -U ${app_user} -c "create database ${tmp1_target_db}" postgres
pg_restore --verbose --host=${target_host} --username=${app_user} --dbname=${tmp1_target_db} ${download_path}/${tmpdir} -j ${threads}

# rename (swap) - might need to kill connections
swap_out_query_0="select pg_terminate_backend(pid) from pg_stat_activity where datname='${target_db}'"
swap_out_query_1="alter database ${target_db} rename to ${tmp2_target_db}"
swap_in_query_0="select pg_terminate_backend(pid) from pg_stat_activity where datname='${tmp1_target_db}'"
swap_in_query_1="alter database ${tmp1_target_db} rename to ${target_db}"
drop_old_db_query="select pg_terminate_backend(pid) from pg_stat_activity where datname='${tmp2_target_db}'"
psql -h ${target_host} -U ${app_user} -c "${swap_out_query_0}" postgres
psql -h ${target_host} -U ${app_user} -c "${swap_out_query_1}" postgres
psql -h ${target_host} -U ${app_user} -c "${swap_in_query_0}" postgres
psql -h ${target_host} -U ${app_user} -c "${swap_in_query_1}" postgres
psql -h ${target_host} -U ${app_user} -c "${drop_old_db_query}" postgres
dropdb -h ${target_host} -U ${app_user} ${tmp2_target_db}
rm -rfv ${download_path}/${tmpdir}

echo "---- FINISHED! ------"
echo "Target Database: ${target_db} on ${target_host}"
echo date
psql -h ${target_host} -U ${app_user} -c "SELECT schemaname,relname,n_live_tup FROM pg_stat_user_tables ORDER BY n_live_tup DESC" ${target_db}
