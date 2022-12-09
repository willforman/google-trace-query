#!/bin/bash

dbmate --wait up # Migrate db

# If dbmate has a nonzero exit code, we don't wanna continue
if [ $? -ne 0 ]; then
  echo "Database migration failed, aborting"
  exit 1
fi

# Triggers event every time a file is downloaded to `files/`
# We trigger on `moved_to` instead of `create` because this is triggered when the download is complete by `gsutil`
while read directory action file; do
  if [ "$file" = "${CLOSE_STREAM_FILENAME}" ]; then
    exit 0
  fi
  
  file_path=files/$file

  clickhouse-client \
    --host $CLICKHOUSE_HOST \
    --query "
    INSERT INTO trace.resource_usage
    SELECT
        start_time,
        end_time, 
        collection_id,
        instance_index,
        machine_id,
        alloc_collection_id,
        collection_type,
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
    FROM input('
      start_time DateTime,
      end_time DateTime, 
      collection_id UInt64,
      instance_index UInt32,
      machine_id UInt64,
      alloc_collection_id UInt32,
      collection_type UInt8,
      average_usage Tuple(Float64, Float64),
      maximum_usage Tuple(Float64, Nullable(Float64)),
      random_sample_usage Tuple(Float64, Nullable(Float64)),
      assigned_memory Float32,
      page_cache_memory Float64,
      cycles_per_instruction Nullable(Float64),
      memory_accesses_per_instruction Nullable(Float64),
      sample_rate Float64,
      cpu_usage_distribution Array(Float64),
      tail_cpu_usage_distribution Array(Float64)
    ')
    FORMAT Parquet
" < $file_path

  rm $file_path

  echo "Inserted ${file}"

done < <(inotifywait -m files/ -e moved_to -t 60)

exit 1 # If we timeout watching the directory before the end signal is sent, then something is wrong
