#!/bin/sh

port=$1
cell_id=$2

table_name="instance_usage_$cell_id"

clickhouse-client \
  --port $port \
  --database trace \
  --query "
    CREATE TABLE $table_name (
      start_time DateTime('America/Los_Angeles'),
      end_time DateTime('America/Los_Angeles'),
      collection_id UInt64,
      instance_index UInt32,
      machine_id UInt64,
      alloc_collection_id UInt32,
      alloc_instance_index UInt32,
      collection_type Enum('JOB' = 0, 'ALLOC_SET'),
      average_usage_cpus Float64,
      average_usage_memory Float64,
      maximum_usage_cpus Float64,
      maximum_usage_memory Float64 DEFAULT -1,
      random_sample_usage_cpus Float64,
      random_sample_usage_memory Float64 DEFAULT -1,
      assigned_memory Float32,
      page_cache_memory Float64,
      cycles_per_instruction Float64 DEFAULT -1,
      memory_accesses_per_instruction Float64 DEFAULT -1,
      sample_rate Float64,
      cpu_usage_distribution Array(Float64),
      tail_cpu_usage_distribution Array(Float64)
    )
    ENGINE = MergeTree
    ORDER BY (start_time, end_time, collection_id, machine_id, average_usage_cpus, cycles_per_instruction);
  "

  file_name="https://storage.googleapis.com/clusterdata_2019_${cell_id}_parquet/instance_usage000000000000.parquet"

clickhouse-client \
  --port $port \
  --database trace \
  --query "
  INSERT INTO $table_name
  SETTINGS async_insert=1, wait_for_async_insert=0, async_insert_max_data_size=100000000, max_insert_threads=24, max_threads=24, async_insert_threads=24
  SELECT
      toDateTime((start_time + 1556668200000000) / 1000000) AS start_time,
      toDateTime((end_time + 1556668200000000) / 1000000) AS end_time,
      collection_id,
      instance_index,
      machine_id,
      alloc_collection_id,
      alloc_instance_index,
      CAST(collection_type AS Enum('JOB' = 0, 'ALLOC_SET')) AS collection_type,
      average_usage.1,
      average_usage.2,
      maximum_usage.1,
      maximum_usage.2,
      random_sample_usage.1,
      random_sample_usage.2,
      assigned_memory,
      page_cache_memory,
      cycles_per_instruction,
      memory_accesses_per_instruction,
      sample_rate,
      cpu_usage_distribution,
      tail_cpu_usage_distribution
  FROM s3('$file_name', 'Parquet')
  "
