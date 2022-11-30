-- migrate:up
CREATE TABLE trace.resource_usage (
  start_time DateTime NOT NULL,
  end_time DateTime NOT NULL, 
  collection_ID UInt64 NOT NULL,
  instance_index UInt32 NOT NULL,
  machine_ID UInt64 NOT NULL,
  alloc_collection_ID UInt32 NOT NULL,
  collection_type UInt8 NOT NULL,
  average_usage Nested
  (
    cpus Float64,
    memory Float64
  ) NOT NULL,
  maximum_usage Nested
  (
    cpus Float64,
    memory Float64
  ) NOT NULL,
  random_sampled_usage Nested
  (
    cpus Float64,
    memory Float64
  ) NOT NULL,
  assigned_memory Float32 NOT NULL,
  page_cache_memory Float64 NOT NULL,
  cycles_per_instruction Float64 NOT NULL,
  memory_accesses_per_instruction Float64 NOT NULL,
  sample_rate Float64 NOT NULL,
  cpu_usage_distribution Array(Float64) NOT NULL,
  tail_cpu_usage_distribution Array(Float64) NOT NULL
)
ENGINE = MergeTree
ORDER BY start_time;

-- migrate:down
DROP TABLE resource_usage;
