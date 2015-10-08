kafka:
  image_version: 0.0.1
  data_volume: /data/kafka/data
  log_volume: /data/kafka/log
  broker_port: 9092
  jmx_port: 7203
  topic_logs: $host-op-logs
