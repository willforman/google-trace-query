#!/bin/bash
#
#

work_path="./cell-a/resource-usage"

file_idx=0

num_files=$(find $work_path -maxdepth 1 -type f -name '*.parquet' -printf '.' | wc --char)

echo "found $num_files files"

for parquet_filename in $work_path/*.parquet; do
  
  ((file_idx=file_idx+1))

  # docker run -i --rm --link some-clickhouse-server:clickhouse-server clickhouse-client -m --host clickhouse-server --query="INSERT INTO trace.resource_usage FORMAT Parquet" < "$parquet_filename"
  #
  echo "$parquet_filename"


  if ((file_idx % 100 == 0)); then
    echo "inserted [$file_idx / $num_files]"
  fi
  

done

