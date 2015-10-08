{%- set download_url = salt['pillar.get']('spark:download_url') -%}
{%- set package_md5sum = salt['pillar.get']('spark:package_md5sum') -%}
{%- set spark_folder = salt['pillar.get']('spark:spark_folder') -%}
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
  - java
  - cdh.hive

spark.user:
  user.present:
    - name: spark

spark.download:
  cmd.run:
    - name: curl -L {{ download_url }} -o /tmp/{{ spark_folder }}.tgz
    - creates: /tmp/{{ spark_folder }}.tgz
    - unless: test -f /tmp/{{ spark_folder }}.tgz

/var/run/spark:
  file.directory:
    - user: spark
    - group: spark
    - recurse:
        - user
        - group

/var/log/spark:
  file.directory:
    - user: spark
    - group: spark
    - recurse:
        - user
        - group

spark.install:
  cmd.run:
    - name: tar xzf /tmp/{{ spark_folder }}.tgz -C /opt
    - cwd: /tmp
    - require:
      - cmd: spark.download
      - user: spark.user
      - file: /var/log/spark
      - file: /var/run/spark
  file.directory:
    - name: /opt/{{ spark_folder }}
    - user: spark
    - group: spark
    - recurse:
        - user
        - group

spark.env:
  file.managed:
    - name: /opt/{{ spark_folder }}/conf/spark-env.sh
    - source: salt://apach-spark/files/spark-env.sh
    - template: jinja
    - user: spark
    - group: spark
    - mode: 644
    - context:
      spark_home: /opt/{{ spark_folder }}
      java_home: {{ java_home }}
      master: {{ master_ip }}
    - require:
      - cmd: spark.install

{% if 'spark-master' in grains['roles'] %}
spark.master.service:
  cmd.run:
    - name: /opt/{{ spark_folder }}/sbin/stop-master.sh; /opt/{{ spark_folder }}/sbin/start-master.sh
    - user: spark
    - group: spark
    - cwd: /opt/{{ spark_folder }}/sbin
    - require:
      - file: spark.env
      - sls: cdh.hive
{% endif %}

{% if 'spark-worker' in grains['roles'] %}
spark.worker.service:
  cmd.run:
    - name: /opt/{{ spark_folder }}/sbin/stop-slave.sh; /opt/{{ spark_folder }}/sbin/start-slave.sh spark://{{ master_ip }}:7077
    - user: spark
    - group: spark
    - cwd: /opt/{{ spark_folder }}/sbin
    - require:
      - file: spark.env
      - sls: cdh.hive
{% endif %}
