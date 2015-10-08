{%- set docker_image = salt['pillar.get']('docker:registry') + '/logstash' -%}
{%- set image_version = salt['pillar.get']('logstash:image_version') -%}
{%- set port = salt['pillar.get']('logstash:input_port') -%}
{%- set vol_data = salt['pillar.get']('logstash:data_volume') -%}
{%- set ssl_keys = salt['pillar.get']('ssl:key_folder')%}
{%- set key_file = salt['pillar.get']('ssl:key_file')%}
{%- set crt_file = salt['pillar.get']('ssl:crt_file')%}
{%- set log_topic = salt['pillar.get']('kafka:topic_logs') -%}
{%- set broker_port = salt['pillar.get']('kafka:broker_port') -%}
{%- set get_net_info = salt['util.getNodeNetworks'] -%}
{%- set kafka_ip_dict = salt['mine.get']('roles:kafka', 'grains.item', expr_form='grain') -%}
{%- set kafka_broker = [] -%}
{%- if kafka_ip_dict | length !=0 %}
  {%- for key in kafka_ip_dict.keys() -%}
    {%- set kafka_ip = get_net_info(key)['ipaddr'] %}
    {%- do kafka_broker.append(kafka_ip ~ ':' ~  broker_port) -%}
  {%- endfor -%}
{%- endif -%}


include:
  - docker
  - ssl-key

logstash.create.certs:
  file.directory:
    - name: {{ vol_data }}/certs
    - dir_mode: 755
    - makedirs: True
    - unless: test -d {{ vol_data }}/certs

logstash.cp.certs:
  file.recurse:
    - name: {{ vol_data }}/certs
    - source: salt:/{{ ssl_keys }}
    - makedirs: True
    - require:
      - file: logstash.create.certs

logstash.key.mode:
  file.managed:
    - name: {{ vol_data }}/certs/{{ key_file }}
    - mode: 400
    - require:
      - sls: ssl-key
      - file: logstash.cp.certs

logstash.image:
  docker.pulled:
    - name: {{ docker_image }}
    - tag: {{ image_version }}
    - insecure_registry: True
    - require:
      - sls: docker

logstash.config:
  file.managed:
    - name: {{ vol_data }}/logstash-lumberjack.conf
    - source: salt://logstash-server/files/logstash-lumberjack.conf
    - template: jinja
    - mode: 644
    - context:
      ssl_certificate: /data/certs/{{ crt_file }}
      ssl_key: /data/certs/{{ key_file }}
      kafka_broker: {{ kafka_broker|join(',') }}
      logs_topic: {{ log_topic }}

logstash.volumes:
  docker.running:
    - name: logstash-data
    - image: {{ docker_image }}:{{ image_version }}
    - volumes:
      - {{ vol_data }}: /data
    - check_is_running: False
    - command: chown -R logstash:logstash /data
    - require:
      - docker: logstash.image
      - file: logstash.key.mode

logstash.run:
  docker.running:
    - name: logstash-server
    - image: {{ docker_image }}:{{ image_version }}
    - ports:
      - 9091/tcp:
          HostIp: ""
          HostPort: {{ port }}
    - volumes_from:
        - logstash-data
    - command: "logstash -f /data/logstash-lumberjack.conf"
    - require:
      - docker: logstash.volumes
      - file: logstash.config
