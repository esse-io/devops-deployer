{%- set docker_image = salt['pillar.get']('docker:registry') + '/postgresql' -%}
{%- set image_version = salt['pillar.get']('postgresql:image_version') -%}
{%- set vol_postgres = salt['pillar.get']('postgresql:data_volume') -%}
{%- set postgres_name = salt['pillar.get']('postgresql:container_name') -%}
{%- set env_db_name = salt['pillar.get']('postgresql:zen-web_db_name') + ','
    + salt['pillar.get']('postgresql:oozie_db_name') + ','
    + salt['pillar.get']('postgresql:sharpen_db_name') + ','
    + salt['pillar.get']('postgresql:hive_db_name') + ','
    + salt['pillar.get']('postgresql:gitlab_db_name') + ','
    + salt['pillar.get']('postgresql:gerrit_db_name') -%}
{%- set env_db_user = salt['pillar.get']('postgresql:db_user') -%}
{%- set env_db_pass = salt['pillar.get']('postgresql:db_pass') -%}
{%- set port = salt['pillar.get']('postgresql:port') -%}


include:
  - docker

postgresql.image:
  docker.pulled:
    - name: {{ docker_image }}
    - tag: {{ image_version }}
    - insecure_registry: True
    - require:
      - sls: docker

postgresql.run:
  docker.running:
    - name: {{ postgres_name }}
    - image: {{ docker_image }}:{{ image_version }}
    - volumes:
      - {{ vol_postgres }}: /var/lib/postgresql 
    - ports:
      - 5432/tcp:
          HostIp: ""
          HostPort: {{ port }}
    - environment:
        "DB_NAME": '{{ env_db_name }}'
        "DB_USER": '{{ env_db_user }}'
        "DB_PASS": '{{ env_db_pass }}'
    - require:
      - docker: postgresql.image

