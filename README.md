# Google Trace Dataset 2019 Analysis

This repo sets up a performant on-premises system to query the [2019 Google Trace Dataset](https://github.com/google/cluster-data).
It stores the dataset in a [Clickhouse](https://clickhouse.com) database, which was chosen because it's a OLAP database suited for this workload.

### Setup

We will run Clickhouse in Docker. Choose where you want to store all the database files (`var/lib/clickhouse` in the Docker container) on your local machine. This enables:
- persistence: if the container shuts down we can run the container again with the same files, so we don't have to insert again
- choosing where you store the data, so you can instead store it on an external drive

The default is `.db` in the root of this repository:

```
mkdir .db
```

Choose which port you want to expose on your host machine for the database, then start it in the background:

```
docker run -d --name google-trace-db -v <path to database dir>:/var/lib/clickhouse -p <db port>:9000 --ulimit nofile=262144:262144 clickhouse/clickhouse-server:22-alpine
```

To insert data into our database, use `cmd.sh`:

```
./cmd.sh --help               
usage: ./cmd.sh <db port> <table name> <cell id>

arguments:
  db port 
  table name:
    - instance-usage
  cell id: a - h
```

To enter a client:

```
docker run -it --rm --network host --entrypoint clickhouse-client clickhouse/clickhouse-server:22-alpine --database trace --port <db port>
```

### Table Schemas

```
instance_usage
┌─name────────────────────────────┬─type──────────────────────────────┬─default_type─┬─default_expression─┐
│ start_time                      │ DateTime('America/Los_Angeles')   │              │                    │
│ end_time                        │ DateTime('America/Los_Angeles')   │              │                    │
│ collection_id                   │ UInt64                            │              │                    │
│ instance_index                  │ UInt32                            │              │                    │
│ machine_id                      │ UInt64                            │              │                    │
│ alloc_collection_id             │ UInt32                            │              │                    │
│ alloc_instance_index            │ UInt32                            │              │                    │
│ collection_type                 │ Enum8('JOB' = 0, 'ALLOC_SET' = 1) │              │                    │
│ average_usage_cpus              │ Float64                           │              │                    │
│ average_usage_memory            │ Float64                           │              │                    │
│ maximum_usage_cpus              │ Float64                           │              │                    │
│ maximum_usage_memory            │ Float64                           │ DEFAULT      │ -1                 │
│ random_sample_usage_cpus        │ Float64                           │              │                    │
│ random_sample_usage_memory      │ Float64                           │ DEFAULT      │ -1                 │
│ assigned_memory                 │ Float32                           │              │                    │
│ page_cache_memory               │ Float64                           │              │                    │
│ cycles_per_instruction          │ Float64                           │ DEFAULT      │ -1                 │
│ memory_accesses_per_instruction │ Float64                           │ DEFAULT      │ -1                 │
│ sample_rate                     │ Float64                           │              │                    │
│ cpu_usage_distribution          │ Array(Float64)                    │              │                    │
│ tail_cpu_usage_distribution     │ Array(Float64)                    │              │                    │
└─────────────────────────────────┴───────────────────────────────────┴──────────────┴────────────────────┘
```

```
instance_events
┌─name────────────────────┬─type──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┬─default_type─┬─default_expression─┐
│ time                    │ DateTime('America/Los_Angeles')                                                                                                                                                       │              │                    │
│ type                    │ Enum8('SUBMIT' = 0, 'QUEUE' = 1, 'ENABLE' = 2, 'SCHEDULE' = 3, 'EVICT' = 4, 'FAIL' = 5, 'FINISH' = 6, 'KILL' = 7, 'LOST' = 8, 'UPDATE_PENDING' = 9, 'UPDATE_RUNNING' = 10)            │              │                    │
│ collection_id           │ Int64                                                                                                                                                                                 │              │                    │
│ scheduling_class        │ Enum8('MOST_INSENSITIVE' = 0, 'INSENSITIVE' = 1, 'SENSITIVE' = 2, 'MOST_SENSITIVE' = 3)                                                                                               │              │                    │
│ missing_type            │ Enum8('MISSING_TYPE_NONE' = 0, 'SNAPSHOT_BUT_NO_TRANSITION' = 1, 'NO_SNAPSHOT_OR_TRANSITION' = 2, 'EXISTS_BUT_NO_CREATION' = 3, 'TRANSITION_MISSING_STEP' = 4, 'TOO_MANY_EVENTS' = 5) │              │                    │
│ collection_type         │ Enum8('JOB' = 0, 'ALLOC_SET' = 1)                                                                                                                                                     │              │                    │
│ priority                │ Int32                                                                                                                                                                                 │              │                    │
│ alloc_collection_id     │ Int64                                                                                                                                                                                 │ DEFAULT      │ -1                 │
│ instance_index          │ Int32                                                                                                                                                                                 │              │                    │
│ machine_id              │ Int64                                                                                                                                                                                 │ DEFAULT      │ -1                 │
│ alloc_instance_index    │ Int32                                                                                                                                                                                 │ DEFAULT      │ -1                 │
│ resource_request_cpus   │ Float64                                                                                                                                                                               │ DEFAULT      │ -1                 │
│ resource_request_memory │ Float64                                                                                                                                                                               │ DEFAULT      │ -1                 │
└─────────────────────────┴───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┴──────────────┴────────────────────┘
```

```
collection_events
┌─name───────────────────────┬─type──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┬─default_type─┬─default_expression─┐
│ time                       │ DateTime('America/Los_Angeles')                                                                                                                                                       │              │                    │
│ type                       │ Enum8('SUBMIT' = 0, 'QUEUE' = 1, 'ENABLE' = 2, 'SCHEDULE' = 3, 'EVICT' = 4, 'FAIL' = 5, 'FINISH' = 6, 'KILL' = 7, 'LOST' = 8, 'UPDATE_PENDING' = 9, 'UPDATE_RUNNING' = 10)            │              │                    │
│ collection_id              │ Int64                                                                                                                                                                                 │              │                    │
│ scheduling_class           │ Enum8('MOST_INSENSITIVE' = 0, 'INSENSITIVE' = 1, 'SENSITIVE' = 2, 'MOST_SENSITIVE' = 3)                                                                                               │              │                    │
│ missing_type               │ Enum8('MISSING_TYPE_NONE' = 0, 'SNAPSHOT_BUT_NO_TRANSITION' = 1, 'NO_SNAPSHOT_OR_TRANSITION' = 2, 'EXISTS_BUT_NO_CREATION' = 3, 'TRANSITION_MISSING_STEP' = 4, 'TOO_MANY_EVENTS' = 5) │              │                    │
│ collection_type            │ Enum8('JOB' = 0, 'ALLOC_SET' = 1)                                                                                                                                                     │              │                    │
│ priority                   │ Int32                                                                                                                                                                                 │              │                    │
│ alloc_collection_id        │ Int64                                                                                                                                                                                 │ DEFAULT      │ -1                 │
│ user                       │ String                                                                                                                                                                                │              │                    │
│ collection_name            │ String                                                                                                                                                                                │              │                    │
│ collection_logical_name    │ String                                                                                                                                                                                │              │                    │
│ parent_collection_id       │ Int64                                                                                                                                                                                 │ DEFAULT      │ -1                 │
│ start_after_collection_ids │ Array(Int64)                                                                                                                                                                          │              │                    │
│ max_per_machine            │ Int32                                                                                                                                                                                 │ DEFAULT      │ -1                 │
│ max_per_switch             │ Int32                                                                                                                                                                                 │ DEFAULT      │ -1                 │
│ vertical_scaling           │ Enum8('VERTICAL_SCALING_SETTING_UNKNOWN' = 0, 'VERTICAL_SCALING_OFF' = 1, 'VERTICAL_SCALING_CONSTRAINED' = 2, 'VERTICAL_SCALING_FULLY_AUTOMATED' = 3)                                 │              │                    │
│ scheduler                  │ Enum8('SCHEDULER_DEFAULT' = 0, 'SCHEDULER_BATCH' = 1)                                                                                                                                 │              │                    │
└────────────────────────────┴───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┴──────────────┴────────────────────┘
```

```
machine_events
┌─name────────────┬─type───────────────────────────────────────────────────────────────────┬─default_type─┬─default_expression─┐
│ time            │ DateTime('America/Los_Angeles')                                        │              │                    │
│ machine_id      │ Int64                                                                  │              │                    │
│ type            │ Enum8('EVENT_TYPE_UNKNOWN' = 0, 'ADD' = 1, 'REMOVE' = 2, 'UPDATE' = 3) │              │                    │
│ switch_id       │ String                                                                 │              │                    │
│ capacity_cpus   │ Float64                                                                │ DEFAULT      │ -1                 │
│ capacity_memory │ Float64                                                                │ DEFAULT      │ -1                 │
│ platform_id     │ String                                                                 │              │                    │
└─────────────────┴────────────────────────────────────────────────────────────────────────┴──────────────┴────────────────────┘
```

```
machine_attributes
┌─name───────┬─type────────────────────────────┬─default_type─┬─default_expression─┐
│ time       │ DateTime('America/Los_Angeles') │              │                    │
│ machine_id │ Int64                           │              │                    │
│ name       │ String                          │              │                    │
│ value      │ String                          │ DEFAULT      │ ''                 │
│ deleted    │ Bool                            │              │                    │
└────────────┴─────────────────────────────────┴──────────────┴────────────────────┘
```
