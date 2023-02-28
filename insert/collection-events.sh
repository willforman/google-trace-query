#!/bin/sh

port=$1
cell_id=$2

table_name="collection_events_$cell_id"

clickhouse-client \
  --port $port \
  --database trace \
  --query "
    CREATE TABLE $table_name (
      time DateTime('America/Los_Angeles'),
      type Enum('SUBMIT' = 0, 'QUEUE', 'ENABLE', 'SCHEDULE', 'EVICT', 'FAIL', 'FINISH', 'KILL', 'LOST', 'UPDATE_PENDING', 'UPDATE_RUNNING'),
      collection_id Int64,
      scheduling_class Enum('MOST_INSENSITIVE' = 0, 'INSENSITIVE', 'SENSITIVE', 'MOST_SENSITIVE'),
      missing_type Enum('MISSING_TYPE_NONE' = 0, 'SNAPSHOT_BUT_NO_TRANSITION', 'NO_SNAPSHOT_OR_TRANSITION', 'EXISTS_BUT_NO_CREATION', 'TRANSITION_MISSING_STEP', 'TOO_MANY_EVENTS'),
      collection_type Enum('JOB' = 0, 'ALLOC_SET'),
      priority Int32,
      alloc_collection_id Int64 DEFAULT -1,
      user String,
      collection_name String,
      collection_logical_name String,
      parent_collection_id Int64 DEFAULT -1,
      start_after_collection_ids Array(Int64),
      max_per_machine Int32 DEFAULT -1,
      max_per_switch Int32 DEFAULT -1,
      vertical_scaling Enum('VERTICAL_SCALING_SETTING_UNKNOWN' = 0, 'VERTICAL_SCALING_OFF', 'VERTICAL_SCALING_CONSTRAINED', 'VERTICAL_SCALING_FULLY_AUTOMATED'),
      scheduler Enum('SCHEDULER_DEFAULT' = 0, 'SCHEDULER_BATCH')
    )
    ENGINE = MergeTree
    ORDER BY (collection_id, collection_name, collection_logical_name, scheduling_class, priority);
  "

file_name="https://storage.googleapis.com/clusterdata_2019_${cell_id}/collection_events-*.json.gz"

clickhouse-client \
  --port $port \
  --database trace \
  --query "
  INSERT INTO $table_name
  SETTINGS async_insert=1, wait_for_async_insert=0, async_insert_max_data_size=100000000, max_insert_threads=24, max_threads=24, async_insert_threads=24
  SELECT 
    toDateTime((time + 1556668200000000) / 1000000) AS time,
    CAST(type AS Enum('SUBMIT' = 0, 'QUEUE', 'ENABLE', 'SCHEDULE', 'EVICT', 'FAIL', 'FINISH', 'KILL', 'LOST', 'UPDATE_PENDING', 'UPDATE_RUNNING')) AS type,
    collection_id,
    CAST(scheduling_class AS Enum('MOST_INSENSITIVE' = 0, 'INSENSITIVE', 'SENSITIVE', 'MOST_SENSITIVE')) AS scheduling_class,
    CAST(ifNull(missing_type, 0) AS Enum('MISSING_TYPE_NONE' = 0, 'SNAPSHOT_BUT_NO_TRANSITION', 'NO_SNAPSHOT_OR_TRANSITION', 'EXISTS_BUT_NO_CREATION', 'TRANSITION_MISSING_STEP', 'TOO_MANY_EVENTS')) AS missing_type,
    CAST(collection_type AS Enum('JOB' = 0, 'ALLOC_SET')) AS collection_type,
    priority,
    alloc_collection_id,
    user,
    collection_name,
    collection_logical_name,
    parent_collection_id,
    start_after_collection_ids,
    max_per_machine,
    max_per_switch,
    CAST(ifNull(vertical_scaling, 0) AS Enum('VERTICAL_SCALING_SETTING_UNKNOWN' = 0, 'VERTICAL_SCALING_OFF', 'VERTICAL_SCALING_CONSTRAINED', 'VERTICAL_SCALING_FULLY_AUTOMATED')) AS vertical_scaling,
    CAST(ifNull(scheduler, 0) AS Enum('SCHEDULER_DEFAULT' = 0, 'SCHEDULER_BATCH')) AS scheduler
  FROM s3('$file_name', 'JSONEachRow')
  "

