{%- set nodes = salt['pillar.get']('zookeeper:node_number')|int -%}
{%- set docker_image = salt['pillar.get']('docker:registry') + '/zookeeper' -%}
{%- set image_version = salt['pillar.get']('zookeeper:image_version') -%}
{%- set client_port = salt['pillar.get']('zookeeper:client_port')|int -%}
{%- set peer_port = salt['pillar.get']('zookeeper:peer_port')|int -%}
{%- set leader_port = salt['pillar.get']('zookeeper:leader_port')|int -%}
{%- set vol_data = salt['pillar.get']('zookeeper:data_volume') -%}
{%- set vol_conf = salt['pillar.get']('zookeeper:conf_volume') -%}

include:
  - docker

zookeeper.image:
  docker.pulled:
    - name: {{ docker_image }}
    - tag: {{ image_version }}
    - insecure_registry: True
    - require:
      - sls: docker

{% for i in range(0, nodes) %}
zookeeper.run_{{ i + 1 }}:
  docker.running:
    - name: zookeeper_{{ i + 1 }}
    - image: {{ docker_image }}:{{ image_version }}
    - ports:
      - 2181/tcp: 
          HostIp: ""
          HostPort: {{ client_port + i}}
      - 3888/tcp: 
          HostIp: ""
          HostPort: {{ leader_port + i}}
      - 2888/tcp: 
          HostIp: ""
          HostPort: {{ peer_port + i}}
    - environment:
        'ZOO_ID': {{ i + 1 }}
    - volumes:
      - {{ vol_data }}/{{ i + 1 }}: /var/lib/zookeeper
      - {{ vol_conf }}: /opt/zookeeper/conf
    - require:
      - docker: zookeeper.image
{%- endfor %}

zookeeper.file.zoo:
  file.managed:
    - name: /tmp/zoo.cfg.tmp
    - source: salt://zookeeper/files/zoo.cfg.tmp
    - template: jinja
    - mode: 644
    - require:
      {%- for i in range(0, nodes) %}
      - docker: zookeeper.run_{{ i + 1 }}
      {%- endfor %}

zookeeper.file.update:
  file.managed:
    - name: /tmp/update_zoo.sh
    - source: salt://zookeeper/files/update_zoo.sh
    - template: jinja
    - mode: 755
    - context:
      vol_conf: {{ vol_conf }}
      node_count: {{ nodes }}
    - require:
      {%- for i in range(0, nodes) %}
      - docker: zookeeper.run_{{ i + 1 }}
      {%- endfor %}

zookeeper.file.utils:
  file.managed:
    - name: /tmp/docker-ip
    - source: salt://utils/docker-ip
    - mode: 755
    - require:
      {%- for i in range(0, nodes) %}
      - docker: zookeeper.run_{{ i + 1 }}
      {%- endfor %}

zookeeper.config:
  cmd.run:
    - name: /tmp/update_zoo.sh
    - cwd: /tmp
    - require:
      - file: zookeeper.file.zoo
      - file: zookeeper.file.utils
      - file: zookeeper.file.update

