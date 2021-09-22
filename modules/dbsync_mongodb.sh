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

source ${dbsync_config_file}

mongodump --host=${source_host} --username=${app_user} --password="${app_user_password}" --db=${source_db} --authenticationDatabase=${mongodb_auth_db} --numParallelCollections=${threads} --out=${download_path}/${tmpdir}

echo "`date "+%D %T"`: Finished downloading ${source_db}"

if [ ${source_db} != ${target_db} ]; then
  mv -v ${download_path}/${tmpdir}/${source_db} ${download_path}/${tmpdir}/${target_db}
fi

# mongorestore to tmp1
mongorestore --host=${target_host} --username=${app_user} --password="${app_user_password}" --authenticationDatabase=${mongodb_auth_db} --numParallelCollections=${threads} --dir=${download_path}/${tmpdir}

rm -rfv ${download_path}/${tmpdir}

echo "------------- FINISHED! ------------------"
