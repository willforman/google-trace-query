# Google Trace Dataset 2019 Analysis

The goal of this is to set up a performant on-premises system to query the [2019 Google Trace Dataset](https://github.com/google/cluster-data).
It stores the dataset in a [Clickhouse](https://clickhouse.com) database, which was chosen because it's a OLAP database suited for this workload.

### Initialize Database

```
docker compose up -d
```

This does:
1. Creates clickhouse-server instance
1. Creates tables using a [dbmate](https://github.com/amacneil/dbmate) migration

### Query the Database

```
docker run -it --rm --network google-trace_default --entrypoint clickhouse-client clickhouse/clickhouse-server --host google-trace-db-1
```

Creates a clickhouse client to perform queries with.
