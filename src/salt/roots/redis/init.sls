{%- set docker_image = salt['pillar.get']('docker:registry') + '/redis' -%}
{%- set image_version = salt['pillar.get']('redis:image_version') -%}
{%- set vol_redis = salt['pillar.get']('redis:config_volume') -%}
{%- set redis_name = salt['pillar.get']('redis:container_name') -%}
include:
  - docker

redis.image:
  docker.pulled:
    - name: {{ docker_image }}
    - tag: {{ image_version }}
    - insecure_registry: True
    - require:
      - sls: docker

redis.run:
  docker.running:
    - name: {{ redis_name }}
    - image: {{ docker_image }}:{{ image_version }}
    - volumes:
      - {{ vol_redis }}: /var/lib/redis 
    - require:
      - docker: redis.image

