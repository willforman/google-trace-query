#!/bin/sh
docker run --rm --name google-trace-insert -v $(pwd)/insert:/insert --entrypoint "/bin/bash" --net host clickhouse/clickhouse-server:23.3-alpine /insert/insert-data.sh $1 $2 $3
