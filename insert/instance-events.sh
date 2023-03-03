#!/bin/sh

port=$1
cell_id=$2

table_name="instance_events_$cell_id"

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
      instance_index Int32,
      machine_id Int64 DEFAULT -1,
      alloc_instance_index Int32 DEFAULT -1,
      resource_request_cpus Float64 DEFAULT -1,
      resource_request_memory Float64 DEFAULT -1
    )
    ENGINE = MergeTree
    ORDER BY (time, collection_id, instance_index, machine_id, resource_request_cpus, resource_request_memory);
  "

# Add constraints later
# constraint Array(Nested
#   name String
#   value String
#   relation Enum('EQUAL' = 0, 'NOT_EQUAL', 'LESS_THAN', 'GREATER_THAN', 'LESS_THAN_EQUAL', 'GREATER_THAN_EQUAL', 'PRESENT', 'NOT_PRESENT')
# ))
# constraint_name String,
# constraint_value String,
# constraint_relation Enum('EQUAL' = 0, 'NOT_EQUAL', 'LESS_THAN', 'GREATER_THAN', 'LESS_THAN_EQUAL', 'GREATER_THAN_EQUAL', 'PRESENT', 'NOT_PRESENT')

file_name="https://storage.googleapis.com/clusterdata_2019_${cell_id}/instance_events-000000000000.json.gz"

clickhouse-client \
  --port $port \
  --database trace \
  --query "
  INSERT INTO $table_name
  SETTINGS async_insert=1, wait_for_async_insert=0, async_insert_max_data_size=100000000, max_insert_threads=24, max_threads=24, async_insert_threads=24
  SELECT 
    toDateTime((time + 1556668200000000) / 1000000),
    CAST(type AS Enum('SUBMIT' = 0, 'QUEUE', 'ENABLE', 'SCHEDULE', 'EVICT', 'FAIL', 'FINISH', 'KILL', 'LOST', 'UPDATE_PENDING', 'UPDATE_RUNNING')),
    collection_id,
    CAST(scheduling_class AS Enum('MOST_INSENSITIVE' = 0, 'INSENSITIVE', 'SENSITIVE', 'MOST_SENSITIVE')),
    CAST(ifNull(missing_type, 0) AS Enum('MISSING_TYPE_NONE' = 0, 'SNAPSHOT_BUT_NO_TRANSITION', 'NO_SNAPSHOT_OR_TRANSITION', 'EXISTS_BUT_NO_CREATION', 'TRANSITION_MISSING_STEP', 'TOO_MANY_EVENTS')),
    CAST(collection_type AS Enum('JOB' = 0, 'ALLOC_SET')),
    priority,
    alloc_collection_id,
    instance_index,
    machine_id,
    alloc_instance_index,
    resource_request['cpus'],
    resource_request['memory']
  FROM s3('$file_name', 'JSONEachRow')
  "
