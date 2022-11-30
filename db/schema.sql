
--
-- Database schema
--

CREATE DATABASE trace IF NOT EXISTS;

CREATE TABLE trace.resource_usage
(
    `start_time` DateTime,
    `end_time` DateTime,
    `collection_ID` UInt64,
    `instance_index` UInt32,
    `machine_ID` UInt64,
    `alloc_collection_ID` UInt32,
    `collection_type` UInt8,
    `average_usage.cpus` Array(Float64),
    `average_usage.memory` Array(Float64),
    `maximum_usage.cpus` Array(Float64),
    `maximum_usage.memory` Array(Float64),
    `random_sampled_usage.cpus` Array(Float64),
    `random_sampled_usage.memory` Array(Float64),
    `assigned_memory` Float32,
    `page_cache_memory` Float64,
    `cycles_per_instruction` Float64,
    `memory_accesses_per_instruction` Float64,
    `sample_rate` Float64,
    `cpu_usage_distribution` Array(Float64),
    `tail_cpu_usage_distribution` Array(Float64)
)
ENGINE = MergeTree
ORDER BY start_time
SETTINGS index_granularity = 8192;

CREATE TABLE trace.schema_migrations
(
    `version` String,
    `ts` DateTime DEFAULT now(),
    `applied` UInt8 DEFAULT 1
)
ENGINE = ReplacingMergeTree(ts)
PRIMARY KEY version
ORDER BY version
SETTINGS index_granularity = 8192;


--
-- Dbmate schema migrations
--

INSERT INTO schema_migrations (version) VALUES
    ('20221128035842');
