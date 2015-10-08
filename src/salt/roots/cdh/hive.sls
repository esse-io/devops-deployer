{%- set get_net_info = salt['util.getNodeNetworks'] -%}
{%- set postgres_port = salt['pillar.get']('postgresql:port')-%}
{%- set hive_db = salt['pillar.get']('postgresql:hive_db_name')-%}
{%- set username = salt['pillar.get']('postgresql:db_user')-%}
{%- set password = salt['pillar.get']('postgresql:db_pass')-%}
{%- set jdbc_url = salt['pillar.get']('postgresql:jdbc_url')-%}
{%- set jdbc_jar = salt['pillar.get']('postgresql:jdbc_jar')-%}

{%- set ps_ip_dict = salt['mine.get']('roles:postgresql', 'grains.item', expr_form='grain') -%}
{%- if ps_ip_dict | length !=0 %}
{%- set ps_ip = get_net_info(ps_ip_dict.keys()[0])['ipaddr'] %}
{%- else -%}
{%- set ps_ip = '' %}
{%- endif -%}

include:
  - cdh.repo
  - java

cdh.hive.install:
  pkg.installed:
    - pkgs:
      - hive
      - postgresql
    - require:
      - sls: cdh.repo
{# TODO: Need require java installation here #}

cdh.hive.jdbc:
  cmd.run:
    - name: wget {{ jdbc_url }}/{{ jdbc_jar }}
    - cwd: /usr/lib/hive/lib/
    - unless: test -f /usr/lib/hive/lib/{{ jdbc_jar }}

cdh.hive.postgresql:
  cmd.run:
    - name: psql -h {{ ps_ip }} -p {{ postgres_port }} -f ./hive-schema-1.1.0.postgres.sql -U {{ username }} -d {{ hive_db }}
    - env:
      - PGPASSWORD: '{{ password }}'
    - cwd: /usr/lib/hive/scripts/metastore/upgrade/postgres/
    - require:
      - pkg: cdh.hive.install

cdh.hive.config:
  file.managed:
    - name: /etc/hive/conf/hive-site.xml
    - source: salt://cdh/files/hive-site.xml
    - template: jinja
    - mode: 644
    - context:
      hostname: {{ ps_ip }}
      port: {{ postgres_port }}
      db: {{ hive_db }}
      username: {{ username }}
      password: {{ password }}
    - require:
      - pkg: cdh.hive.install
      - cmd: cdh.hive.jdbc
