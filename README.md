# Google Trace Dataset 2019 Analysis

This repo sets up a performant on-premises system to query the [2019 Google Trace Dataset](https://github.com/google/cluster-data).
It stores the dataset in a [Clickhouse](https://clickhouse.com) database, which was chosen because it's a OLAP database suited for this workload.

### Initialize Database

Before running, run the below command to set:
- `HOST_FILES_DIR`: where files are temporarily stored before they are inserted into the database
- `HOST_DATABASE_DIR`: where the clickhouse database. The reason this is used is if you have an external drive that you want to store data on.
- `HOST_PORT`: port you want to expose the database on, default is 9000 but you may want to use a different port

```
tee -a .env << EOF
HOST_FILES_DIR=./.data/files
HOST_DATABASE_DIR=./.data/db
HOST_PORT=9000
EOF
```

By default, it stores the data in this repo at `.data` (which is gitignored). If you use this, make sure to run:

```
mkdir -p .data/files
mkdir -p .data/db
```

Now, you can run this command to initialize the database:

```
docker compose -p google-trace up -d
```

This orchestrates 3 containers:

1. Creates an instance of our database (clickhouse), and stays running indefinitely
1. Downloads the files from Google Cloud Storage and stores them at `HOST_FILES_DIR`
1. Watches `HOST_FILES_DIR` and any time a new file comes in, inserts it to the database

### Query the Database

```
docker run -it --rm --network google-trace_default --entrypoint clickhouse-client clickhouse/clickhouse-server:22-alpine --host google-trace-db-1
```

Creates a clickhouse client to perform queries with.
