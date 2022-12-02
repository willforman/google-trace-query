#!/bin/bash

for (( file_num=1; file_num<=$TOT_FILES; file_num++ )); do

  file_num_with_padding=$(printf "%012d" $file_num)
  file_name="instance_usage${file_num_with_padding}.parquet"

  gs_path="gs://clusterdata_2019_a_parquet/${file_name}"

  gsutil cp $gs_path files

done

# We will write now a file to let the script watching this directory
# know we are done.
# This is a hacky way to trigger the `moved_to` event, see `insert-data.sh` why we do this.
touch files/a
mv files/a files/${CLOSE_STREAM_FILENAME}
