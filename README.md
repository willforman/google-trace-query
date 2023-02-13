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
