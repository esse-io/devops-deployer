{%- set get_net_info = salt['util.getNodeNetworks'] -%}
{%- set postgres_port = salt['pillar.get']('postgresql:port')-%}
{%- set oozie_db = salt['pillar.get']('postgresql:oozie_db_name')-%}
{%- set username = salt['pillar.get']('postgresql:db_user')-%}
{%- set password = salt['pillar.get']('postgresql:db_pass')-%}
{%- set web_console_url = salt['pillar.get']('cdh:oozie_web_ext') -%}
{%- set oozie_web_ext_hash = salt['pillar.get']('cdh:oozie_web_ext_hash') -%}

{%- set ps_ip_dict = salt['mine.get']('roles:postgresql', 'grains.item', expr_form='grain') -%}
{%- if ps_ip_dict | length !=0 %}
{%- set ps_ip = get_net_info(ps_ip_dict.keys()[0])['ipaddr'] %}
{%- else -%}
{%- set ps_ip = '' %}
{%- endif -%}

{%- set nn_ip_dict = salt['mine.get']('roles:hadoop-namenode', 'grains.item', expr_form='grain') -%}
{%- if nn_ip_dict | length !=0 %}
{%- set nn_ip = get_net_info(nn_ip_dict.keys()[0])['ipaddr'] %}
{%- else -%}
{%- set nn_ip = '' %}
{%- endif -%}
{%- set nn_rpc_port = salt['pillar.get']('cdh:namenode_rpc_port') -%}
{%- set hdfs_url = 'hdfs://' ~ nn_ip ~ ':' ~ nn_rpc_port -%}

{%- set oozie_ip_dict = salt['mine.get']('roles:oozie-server', 'grains.item', expr_form='grain') -%}
{%- if oozie_ip_dict | length !=0 %}
{%- set oozie_ip = get_net_info(oozie_ip_dict.keys()[0])['ipaddr'] %}
{%- else -%}
{%- set oozie_ip = '' %}
{%- endif -%}

include:
  - cdh.repo
  - java

{% if 'oozie-server' in grains['roles'] %}
cdh.oozie.install:
  pkg.installed:
    - pkgs:
      - oozie
    - require:
      - sls: cdh.repo

cdh.oozie.alternatives:
  alternatives.install:
    - name: oozie-tomcat-conf
    - path: /etc/oozie/tomcat-conf.https
    - link: /var/lib/oozie
    - priority: 30
    - require:
      - pkg: cdh.oozie.install

cdh.oozie.config:
  file.managed:
    - name: /etc/oozie/conf/oozie-site.xml
    - source: salt://cdh/files/oozie-site.xml
    - template: jinja
    - mode: 644
    - context:
      hostname: {{ ps_ip }}
      port: {{ postgres_port }}
      db: {{ oozie_db }}
      username: {{ username }}
      password: {{ password }}
    - require:
      - alternatives: cdh.oozie.alternatives

cdh.oozie.web_console:
  archive.extracted:
    - name:  /var/lib/oozie
    - source: {{ web_console_url }}
    - source_hash: {{ oozie_web_ext_hash }}
    - archive_format: zip
    - user: oozie
    - group: oozie
    - if_missing: /var/lib/oozie/ext-2.2
    - keep: True
    - require:
      - file: cdh.oozie.config

cdh.oozie.postconfig:
  cmd.script:
    - name: /tmp/oozie_postconfig.sh
    - source: salt://cdh/files/oozie_postconfig.sh
    - template: jinja
    - cwd: /usr/lib/oozie/bin
    - user: oozie


cdh.oozie.hadoop.configure:
  file.managed:
    - name: /etc/oozie/conf/hadoop-conf/core-site.xml
    - source: salt://cdh/files/core-site.xml
    - template: jinja
    - mode: 644
    - context:
      namenode_host: {{ nn_ip }}
      namenode_port: {{ nn_rpc_port }}
      oozie_host: {{ oozie_ip }}
    - require:
      - pkg: cdh.oozie.install

cdh.oozie.sharelib:
  cmd.run:
    - name: oozie-setup sharelib create -fs {{ hdfs_url }} -locallib /usr/lib/oozie/oozie-sharelib-yarn
    - user: root
    - require:
      - archive: cdh.oozie.web_console
      - cmd: cdh.oozie.postconfig
      - file: cdh.oozie.hadoop.configure

cdh.oozie.service:
  service.running:
    - name: oozie
    - enable: True
    - restart: True
    - require:
      - cmd: cdh.oozie.sharelib
    - watch:
      - cmd: cdh.oozie.sharelib
{% endif %}

{% if 'oozie-client' in grains['roles'] %}
cdh.oozie-client.install:
  pkg.installed:
    - pkgs:
      - oozie-client
    - require:
      - sls: cdh.repo
{% endif %}