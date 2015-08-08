postgresql:
  data_volume: /data/postgresql
  image_version: 9.4-2
  port: 5432
  container_name: postgresql-gitlab
  sharpen_db_name: sharpen
  hive_db_name: hive_meta
  gerrit_db_name: gerrit
  gitlab_db_name: gitlab
  db_user: devops
  db_pass: p0o9i*UJ
  jdbc_url: https://jdbc.postgresql.org/download
  jdbc_jar: postgresql-9.4-1201.jdbc4.jar