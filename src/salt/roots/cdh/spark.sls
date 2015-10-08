{%- set java_home      = salt['grains.get']('java_home', salt['pillar.get']('java_home', '/usr/lib/java')) %}
{%- set get_net_info = salt['util.getNodeNetworks'] -%}

{%- set spark_master_host = salt['pillar.get']('cdh:spark_master_host')-%}
{%- if spark_master_host != '' -%}
  {%- set master_ip = spark_master_host -%}
{%- else -%}
  {%- set master_ip_dict = salt['mine.get']('roles:spark-master', 'grains.item', expr_form='grain') -%}
  {%- if master_ip_dict | length !=0 %}
    {%- set master_ip = get_net_info(master_ip_dict.keys()[0])['ipaddr'] %}
  {%- else -%}
    {%- set master_ip = '' %}
  {%- endif -%}
{%- endif -%}

include:
  - cdh.repo
  - java

cdh.spark.env:
  file.managed:
    - name: /etc/spark/conf.dist/spark-env.sh
    - source: salt://cdh/files/spark-env.sh
    - template: jinja
    - mode: 644
    - user: spark
    - group: spark
    - context:
      java_home: {{ java_home }}
      master: {{ master_ip }}
    - require:
      {% if 'spark-master' in grains['roles'] %}
      - pkg: cdh.spark-master.install
      {% endif -%}
      {% if 'spark-worker' in grains['roles'] %}
      - pkg: cdh.spark-worker.install
      {% endif %}

{% if 'spark-master' in grains['roles'] %}
cdh.spark-master.install:
  pkg.installed:
    - pkgs:
      - spark-master
    - require:
      - sls: cdh.repo
{# TODO: Need require java installation here #}

cdh.spark-master.service:
  service.running:
    - name: spark-master
    - enable: True
    - restart: True
    - require:
      - pkg: cdh.spark-master.install
      - file: cdh.spark.env
    - watch:
      - file: cdh.spark.env
{% endif %}

{% if 'spark-worker' in grains['roles'] %}
cdh.spark-worker.install:
  pkg.installed:
    - pkgs:
      - spark-worker
    - require:
      - sls: cdh.repo
{# TODO: Need require java installation here #}

cdh.spark-worker.service:
  service.running:
    - name: spark-worker
    - enable: True
    - restart: True
    - require:
      - pkg: cdh.spark-worker.install
      - file: cdh.spark.env
    - watch:
      - file: cdh.spark.env
{% endif %}
