#!/bin/bash

dbmate --wait up # Migrate db

# If dbmate has a nonzero exit code, we don't wanna continue
if [ $? -ne 0 ]; then
  exit 1
fi

# Triggers event every time a file is downloaded to `files/`
# We trigger on `moved_to` instead of `create` because this is triggered when the download is complete by `gsutil`
# TODO: Make sure if files download faster than we can insert into the database, there isn't an issue
while read directory action file; do
  echo "${action} ${file}"

  if [ "$file" = "${CLOSE_STREAM_FILENAME}" ]; then
    exit 0
  fi

  # TODO: Insert this file into the db

done < <(inotifywait -m files/ -e moved_to -t 60)

exit 1 # If we timeout watching the directory before the end signal is sent, then something is wrong
