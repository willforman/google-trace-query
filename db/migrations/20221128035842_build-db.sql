-- migrate:up
CREATE TABLE trace.resource_usage (
  start_time DateTime,
  end_time DateTime, 
  collection_id UInt64,
  instance_index UInt32,
  machine_id UInt64,
  alloc_collection_id UInt32,
  collection_type UInt8,
  average_usage_cpus Float64,
  average_usage_memory Float64,
  maximum_usage_cpus Float64,
  maximum_usage_memory Nullable(Float64),
  random_sampled_usage_cpus Float64,
  random_sampled_usage_memory Nullable(Float64),
  assigned_memory Float32,
  page_cache_memory Float64,
  cycles_per_instruction Nullable(Float64),
  memory_accesses_per_instruction Nullable(Float64),
  sample_rate Float64,
  cpu_usage_distribution Array(Float64),
  tail_cpu_usage_distribution Array(Float64)
)
ENGINE = MergeTree
ORDER BY start_time;

-- migrate:down
DROP TABLE trace.resource_usage;
