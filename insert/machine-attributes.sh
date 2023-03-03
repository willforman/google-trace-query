#!/bin/sh

port=$1
cell_id=$2

table_name="machine_attributes_$cell_id"

clickhouse-client \
  --port $port \
  --database trace \
  --query "
    CREATE TABLE $table_name (
      time DateTime('America/Los_Angeles'),
      machine_id Int64,
      name String,
      value String DEFAULT '',
      deleted Bool
    )
    ENGINE = MergeTree
    ORDER BY (time, machine_id);
  "

file_name="https://storage.googleapis.com/clusterdata_2019_${cell_id}_parquet/machine_attributes.parquet"

clickhouse-client \
  --port $port \
  --database trace \
  --query "
  INSERT INTO $table_name
  SETTINGS async_insert=1, wait_for_async_insert=0, async_insert_max_data_size=100000000, max_insert_threads=24, max_threads=24, async_insert_threads=24
  SELECT 
    toDateTime((time + 1556668200000000) / 1000000),
    machine_id,
    name,
    value,
    deleted
  FROM s3('$file_name', 'Parquet')
  "
