#!/bin/sh
docker run --rm --name google-trace-insert -v $(pwd)/insert:/insert --entrypoint "/bin/bash" -e CH_PORT --net host clickhouse/clickhouse-server:22-alpine /insert/insert-data.sh $1 $2 $3
