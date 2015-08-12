{%- set docker_image = salt['pillar.get']('docker:registry') + '/kafka' -%}
{%- set image_version = salt['pillar.get']('kafka:image_version') -%}
{%- set broker_port = salt['pillar.get']('kafka:broker_port')|int -%}
{%- set jmx_port = salt['pillar.get']('kafka:jmx_port')|int -%}
{%- set vol_data = salt['pillar.get']('kafka:data_volume') -%}
{%- set vol_log = salt['pillar.get']('kafka:log_volume') -%}
{%- set get_net_info = salt['util.getNodeNetworks'] -%}
{%- set get_local_ip = salt['util.getLocalIpaddrs'] -%}
{%- set get_random_id = salt['util.get_random_id'] -%}
{%- set exposed_ip = get_local_ip()[0] -%}
{%- set zookeeper_ip_dict = salt['mine.get']('roles:zookeeper', 'grains.item', expr_form='grain') -%}
{%- set zoo_port = salt['pillar.get']('zookeeper:client_port') -%}
{%- set zoo_number = salt['pillar.get']('zookeeper:node_number')|int -%}
{%- if zookeeper_ip_dict | length !=0 %}
{%- set zoo_ip = get_net_info(zookeeper_ip_dict.keys()[0])['ipaddr'] %}
{%- else -%}
{%- set zoo_ip = '' %}
{%- endif -%}

{%- set zoo_url = [] -%}
{%- for i in range(0, zoo_number) -%}
{%- set port = zoo_port + i %}
{%- do zoo_url.append(zoo_ip ~ ':' ~  port) -%}
{%- endfor -%}

include:
  - docker

kafka.image:
  docker.pulled:
    - name: {{ docker_image }}
    - tag: {{ image_version }}
    - insecure_registry: True
    - require:
      - sls: docker

kafka.run:
  docker.running:
    - name: kafka
    - image: {{ docker_image }}:{{ image_version }}
    - ports:
      - 9092/tcp: 
          HostIp: ""
          HostPort: {{ broker_port }}
      - 7203/tcp: 
          HostIp: ""
          HostPort: {{ jmx_port }}
    - environment:
        'EXPOSED_HOST': {{ exposed_ip }}
        'EXPOSED_PORT': {{ broker_port }}
        'ZOOKEEPER_URL': {{ zoo_url|join(',') }}
        'BROKER_ID': {{ get_random_id() }}
        'BRANCH': master
    - volumes:
      - {{ vol_data }}: /data
      - {{ vol_log }}: /logs
    - require:
      - docker: kafka.image
