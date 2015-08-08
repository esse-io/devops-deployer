{%- set file_roots = salt['pillar.get']('base:salt:file_roots') %}
{%- set ssl_keys = file_roots + '/' + salt['pillar.get']('ssl:key_folder')%}
{%- set key_file = salt['pillar.get']('ssl:key_file')%}
{%- set crt_file = salt['pillar.get']('ssl:crt_file')%}

{# This script should be run on firstbox #}
openssl:
  pkg.installed

{{ ssl_keys }}:
  file.directory:
    - mode: 755
    - makedirs: True

sslkey.generate:
  cmd.script:
    - name: /tmp/ssl_generate.sh
    - source: salt://firstbox/files/ssl_generate.sh
    - template: jinja
    - mode: 644
    - cwd: /tmp
    - shell: /bin/bash
    - require:
      - pkg: openssl
      - file: {{ ssl_keys }}
    - unless: test -f {{ ssl_keys }}/{{ key_file }}
    - context:
      key_file: {{ key_file }}
      ssl_keys: {{ ssl_keys }}
      crt_file: {{ crt_file }}
