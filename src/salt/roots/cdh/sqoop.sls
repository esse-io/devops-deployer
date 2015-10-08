{%- set   hadoop_common_home = salt['pillar.get']('sqoop:hadoop_common_home')  -%}
{%- set hadoop_mapreduce_home = salt['pillar.get']('sqoop:hadoop_mapreduce_home') -%}
{%- set confdir = salt['pillar.get']('sqoop:sqoop_conf_address')  -%}
{%- set jarname = salt['pillar.get']('sqoop:jdbc_jar')  -%}
{%- set connectoin_databases_address_core = salt['pillar.get']('sqoop:connectoin_databases_address_core')  -%}
{%- set core_databases_name = salt['pillar.get']('sqoop:core_databases_name')  -%}
{%- set core_databases_password = salt['pillar.get']('sqoop:core_databases_password')  -%}
{%- set connectoin_databases_address_no_core = salt['pillar.get']('sqoop:connectoin_databases_address_no_core')  -%}
{%- set no_core_databases_name = salt['pillar.get']('sqoop:no_core_databases_name')  -%}
{%- set no_core_databases_password = salt['pillar.get']('sqoop:no_core_databases_password')  -%}

include:
  - cdh.repo

cdh.sqoop.install:
  pkg.installed:
    - pkgs:
        - sqoop
    - require:
        - sls: cdh.repo

sqoop-conf:
  file.managed:
    - name: {{ confdir }}/sqoop-env.sh
    - source: salt://cdh/files/sqoop-env.sh
    - user: sqoop
    - group: sqoop
    - mode: 755
    - template: jinja
    - context:
       hadoop_common_home: {{ hadoop_common_home }}
       hadoop_mapreduce_home: {{ hadoop_mapreduce_home }}
    - require:
       - pkg: cdh.sqoop.install
       - sls: cdh.repo
    - reload: True

jdbc-driver-jar:
  file.managed:
    - name: /usr/lib/sqoop/lib/{{ jarname }}
    - source: salt://cdh/files/{{ jarname }}
    - user: sqoop
    - group: sqoop
    - mode: 755
    - require:
       - pkg: cdh.sqoop.install
       - sls: cdh.repo
sqoop-job:
  file.managed:
    - name: /var/lib/sqoop/sqoop-job.sh
    - source: salt://cdh/files/sqoop-job.sh
    - user: sqoop
    - group: sqoop
    - mode: 755
    - template: jinja
    - context:
       connectoin_databases_address_core: {{ connectoin_databases_address_core }}
       core_databases_name: {{ core_databases_name }}
       core_databases_password: {{ core_databases_password }}
       connectoin_databases_address_no_core: {{ connectoin_databases_address_no_core }}
       no_core_databases_name: {{ no_core_databases_name }}
       no_core_databases_password: {{ no_core_databases_password }}
    - require:
       - pkg: cdh.sqoop.install
       - sls: cdh.repo
  cmd.run:
    - name: /var/lib/sqoop/sqoop-job.sh
    - require:
        - file: /var/lib/sqoop/sqoop-job.sh
    - require:
       - pkg: cdh.sqoop.install
       - sls: cdh.repo