# DBSync

This utility syncs or "refreshes" a target MySQL, MongoDB, or PostgreSQL db from a source, and also does so with zero downtime. It is basically a wrapper of native dump/restore tools of MySQL, MongoDB, and PostgreSQL that allow for multithreading. This was originally developed as a solution to not use mysqldump, and to also quickly and more reliably copy data across multiple servers.

## Supported Database Versions

MySQL 5.x
PostgreSQL 9.4.x - 9.6.x, 10.x, 11.x, 12.x
MongoDB 3.x, 4.x

## Prerequisites

If using for MySQL
* [mydumper/myloader](https://github.com/maxbube/mydumper)
* MySQL command line tools *mysql* and *mysqldump*

If using for PostgreSQL
* pg_dump
* pg_restore
* psql
* dropdb

If using for MongoDB
* mongodump
* mongorestore

## Usage

```bash
dbsync --help

  --source-host
  --target-host
  --source-db
  --target-db
  --conn-type
  --threads
  -h|--help
```

## Dbsync Properties 

```bash
working_directory=     # Dbsync directory


mysql_db_rename_path=  # Parent directory path of mysql_db_rename tool. 

## Database Authentication 
app_user=              # The database username (this user should have adequate permissions to read objects on the source server, and to create/drop/insert on the target server. Usually we just use a superuser)
app_user_password=     # Password for the database user

## Download 
download_path=         # Where dump files are downloaded to temporarily.

## MySQL 
long_query_guard_val=  # Timeout for long query execution in seconds. You should set it to a relatively high number. Recommended: 10800

## MongoDB 
mongodb_auth_db=       # MongoDB Authentication Database (if running against Mongo servers). It's usually "admin".

```