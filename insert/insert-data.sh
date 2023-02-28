#!/bin/bash

set -e # Don't continue execution on error

print_usage() {
  echo "usage: ./cmd.sh <db port> <table name> <cell id>"
  echo ""
  echo "arguments:"
  echo "  db port "
  echo "  table name:"
  echo "    - instance-usage"
  echo "  cell id: a - h"
}

if [ "$#" -eq 1 ] && [ "$1" = help ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
  print_usage
  exit 0
fi

if [ "$#" -ne 3 ]; then
  echo "invalid args passed"
  print_usage
  exit 1
fi

clickhouse-client \
  --port $1 \
  --query "
    CREATE DATABASE IF NOT EXISTS trace
  "

script_name="/insert/$2.sh"

echo "starting inserting now. there will be no printing until finished, this will take a while."

SECONDS=0

$script_name $1 $3

echo "inserting took: $(($SECONDS / 3600))h $((($SECONDS / 60) % 60))m $(($SECONDS % 60))s"
