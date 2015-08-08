
{%- set dn_data_dir = salt['pillar.get']('cdh:datanode_data_volume') -%}
{%- set nn_data_dir = salt['pillar.get']('cdh:namenode_data_volume') -%}
{%- set nn_rpc_port = salt['pillar.get']('cdh:namenode_rpc_port') -%}
{%- set get_net_info = salt['util.getNodeNetworks'] -%}
{%- set java_home      = salt['grains.get']('java_home', salt['pillar.get']('java_home', '/usr/lib/java')) %}

{%- set nn_ip_dict = salt['mine.get']('roles:hadoop-namenode', 'grains.item', expr_form='grain') -%}
{%- if nn_ip_dict | length !=0 %}
{%- set nn_ip = get_net_info(nn_ip_dict.keys()[0])['ipaddr'] %}
{%- else -%}
{%- set nn_ip = '' %}
{%- endif -%}

include:
  - cdh.repo
  - java


{{ dn_data_dir }}:
  file.directory:
    - mode: 755
    - makedirs: True
    - user: hdfs
    - group: hdfs
    - require:
      {% if 'hadoop-datanode' in grains['roles'] %}
      - pkg: cdh.datanode.install
      {% endif -%}
      {% if 'hadoop-namenode' in grains['roles'] %}
      - pkg: cdh.namenode.install
      {% endif %}

{{ nn_data_dir }}:
  file.directory:
    - mode: 755
    - makedirs: True
    - user: hdfs
    - group: hdfs
    - require:
      {% if 'hadoop-datanode' in grains['roles'] %}
      - pkg: cdh.datanode.install
      {% endif -%}
      {% if 'hadoop-namenode' in grains['roles'] %}
      - pkg: cdh.namenode.install
      {% endif %}

cdh.java.configure:
  file.managed:
    - name: /etc/hadoop/conf/hadoop-env.sh
    - source: salt://cdh/files/hadoop-env.sh
    - template: jinja
    - user: hdfs
    - group: hdfs
    - mode: 644
    - context:
      java_home: {{ java_home }}
    - require:
      {% if 'hadoop-datanode' in grains['roles'] %}
      - pkg: cdh.datanode.install
      {% endif -%}
      {% if 'hadoop-namenode' in grains['roles'] %}
      - pkg: cdh.namenode.install
      {% endif %}

cdh.hdfs.configure:
  file.managed:
    - name: /etc/hadoop/conf/hdfs-site.xml
    - source: salt://cdh/files/hdfs-site.xml
    - template: jinja
    - user: hdfs
    - group: hdfs
    - mode: 644
    - context:
      dn_data_dir: file://{{ dn_data_dir }}
      nn_data_dir: file://{{ nn_data_dir }}
    - require:
      - file: {{ dn_data_dir }}
      - file: {{ nn_data_dir }}

cdh.core.configure:
  file.managed:
    - name: /etc/hadoop/conf/core-site.xml
    - source: salt://cdh/files/core-site.xml
    - template: jinja
    - user: hdfs
    - group: hdfs
    - mode: 644
    - context:
      namenode_host: {{ nn_ip }}
      namenode_port: {{ nn_rpc_port }}
    - require:
      {% if 'hadoop-datanode' in grains['roles'] %}
      - pkg: cdh.datanode.install
      {% endif -%}
      {% if 'hadoop-namenode' in grains['roles'] %}
      - pkg: cdh.namenode.install
      {% endif %}


{% if 'hadoop-datanode' in grains['roles'] %}
cdh.datanode.install:
  pkg.installed:
    - pkgs:
      - hadoop-yarn-nodemanager
      - hadoop-hdfs-datanode
      - hadoop-mapreduce
    - require:
      - sls: cdh.repo
{# TODO: Need require java installation here #}

cdh.datanode.service:
  service.running:
    - name: hadoop-hdfs-datanode
    - enable: True
    - restart: True
    - require:
      - pkg: cdh.datanode.install
      - file: cdh.core.configure
      - file: cdh.hdfs.configure
      - file: cdh.java.configure
      {% if 'hadoop-namenode' in grains['roles'] %}
      - service: cdh.namenode.service
      {% endif %}
{% endif %}

{% if 'hadoop-namenode' in grains['roles'] %}
cdh.namenode.install:
  pkg.installed:
    - pkgs:
      - hadoop-yarn-resourcemanager
      - hadoop-hdfs-namenode
    - require:
      - sls: cdh.repo
{# TODO: Need require java installation here #}

cdh.namenode.format:
  cmd.run:
    - name: hdfs namenode -format -nonInteractive
    - unless: test -d {{ nn_data_dir }}/current
    - user: hdfs
    - group: hdfs
    - require:
      - pkg: cdh.namenode.install
      - file: cdh.core.configure
      - file: cdh.hdfs.configure
      - file: cdh.java.configure

cdh.namenode.service:
  service.running:
    - name: hadoop-hdfs-namenode
    - enable: True
    - restart: True
    - require:
      - cmd: cdh.namenode.format
{% endif %}