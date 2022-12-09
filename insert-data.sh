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
  echo "files/${file}"
  if [ "$file" = "${CLOSE_STREAM_FILENAME}" ]; then
    exit 0
  fi

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
        average_usage.cpus,
        average_usage.memory,
        maximum_usage.cpus,
        maximum_usage.memory,
        random_sampled_usage.cpus,
        random_sampled_usage.memory,
        assigned_memory,
        page_cache_memory,
        cycles_per_instruction,
        memory_accesses_per_instruction,
        sample_rate,
        cpu_usage_distribution,
        tail_cpu_usage_distribution
    FROM input('
      start_time DateTime NOT NULL,
      end_time DateTime NOT NULL, 
      collection_id UInt64 NOT NULL,
      instance_index UInt32 NOT NULL,
      machine_id UInt64 NOT NULL,
      alloc_collection_id UInt32 NOT NULL,
      collection_type UInt8 NOT NULL,
      average_usage Nested
      (
        cpus Float64,
        memory Float64
      ) NOT NULL,
      maximum_usage Nested
      (
        cpus Float64,
        memory Float64
      ) NOT NULL,
      random_sampled_usage Nested
      (
        cpus Float64,
        memory Float64
      ) NOT NULL,
      assigned_memory Float32 NOT NULL,
      page_cache_memory Float64 NOT NULL,
      cycles_per_instruction Float64 NOT NULL,
      memory_accesses_per_instruction Float64 NOT NULL,
      sample_rate Float64 NOT NULL,
      cpu_usage_distribution Array(Float64) NOT NULL,
      tail_cpu_usage_distribution Array(Float64) NOT NULL
    ')
    FORMAT Parquet
" < files/${file}

done < <(inotifywait -m files/ -e moved_to -t 60)

exit 1 # If we timeout watching the directory before the end signal is sent, then something is wrong
