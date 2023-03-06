#!/bin/sh

port=$1
cell_id=$2

table_name="machine_events_$cell_id"

clickhouse-client \
  --port $port \
  --database trace \
  --query "
    CREATE TABLE $table_name (
      time DateTime('America/Los_Angeles'),
      machine_id Int64,
      type Enum('EVENT_TYPE_UNKNOWN' = 0, 'ADD', 'REMOVE', 'UPDATE'),
      switch_id String,
      capacity_cpus Float64 DEFAULT -1,
      capacity_memory Float64 DEFAULT -1,
      platform_id String
    )
    ENGINE = MergeTree
    ORDER BY (machine_id, capacity_cpus, capacity_memory);
  "

file_name="https://storage.googleapis.com/clusterdata_2019_${cell_id}/machine_events*.json.gz"

clickhouse-client \
  --port $port \
  --database trace \
  --query "
  INSERT INTO $table_name
  SETTINGS async_insert=1, wait_for_async_insert=0, async_insert_max_data_size=100000000, max_insert_threads=24, max_threads=24, async_insert_threads=24
  SELECT 
    toDateTime((time + 1556668200000000) / 1000000),
    machine_id,
    CAST(type AS Enum('EVENT_TYPE_UNKNOWN' = 0, 'ADD', 'REMOVE', 'UPDATE')),
    switch_id,
    capacity['cpus'],
    capacity['memory'],
    platform_id
  FROM s3('$file_name', 'JSONEachRow')
  "

clickhouse-client \
  --port $port \
  --database trace \
  --receive_timeout 30000 \
  --query "
  OPTIMIZE TABLE $table_name FINAL
  "
