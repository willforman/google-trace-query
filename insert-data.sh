#!/bin/bash

# Migrate db
dbmate --wait up

# If dbmate has a nonzero exit code, we don't wanna continue
if [ $? -ne 0 ]; then
  echo "Database migration failed, aborting"
  exit 1
fi

echo "Database migration complete"

if [[ -z "${NO_STATUS}" ]]; then
  CHUNK_SIZE=100 # How often we print status while inserting

  num_files=$((NUM_FILES))
  iters=$((num_files / CHUNK_SIZE - 1))

  SECONDS=0

  for i in $(seq 0 $iters); do

    file_num_with_padding=$(printf "%010d" $i)
    parquet_name="https://storage.googleapis.com/clusterdata_2019_a_parquet/instance_usage${file_num_with_padding}*.parquet"

    clickhouse-client \
      --host $CLICKHOUSE_HOST \
      --query "
      INSERT INTO trace.resource_usage
      SETTINGS async_insert=1, wait_for_async_insert=0, async_insert_max_data_size=100000000, max_insert_threads=24, max_threads=24, async_insert_threads=24
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
      FROM s3('$parquet_name', 'Parquet')
      "
      
      num_done=$((CHUNK_SIZE * (i + 1)))
      perc_done_dec=$(echo "scale=3; $num_done / $NUM_FILES * 100" | bc)
      perc_done=$(printf %.0f $perc_done_dec)
      seconds_left_str=$(echo "scale=1; ($SECONDS / $num_done) * ($NUM_FILES - $num_done)" | bc)
      seconds_left=$((${seconds_left_str%.*}))

      echo "$num_done / $NUM_FILES -> $perc_done%, left: $(($seconds_left / 3600))h $((($seconds_left / 60) % 60))m $(($seconds_left % 60))s"
  done
else
  echo "Not printing status"

  clickhouse-client \
    --host $CLICKHOUSE_HOST \
    --query "
    INSERT INTO trace.resource_usage
    SETTINGS async_insert=1, wait_for_async_insert=0, async_insert_max_data_size=100000000, max_insert_threads=24, max_threads=24, async_insert_threads=24
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
    FROM s3('https://storage.googleapis.com/clusterdata_2019_a_parquet/instance_usage*.parquet', 'Parquet')
    "
fi

echo "Inserting time elapsed: $(($SECONDS / 3600))h $((($SECONDS / 60) % 60))m $(($SECONDS % 60))s"
echo "Optimizing the table. This may take a while and use a lot of CPU + mem."

clickhouse-client \
  --host $CLICKHOUSE_HOST \
  --query "
  OPTIMIZE TABLE trace.resource_usage FINAL
  "
