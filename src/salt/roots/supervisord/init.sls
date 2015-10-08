{%- set conf_file = salt['pillar.get']('supervisord:sp_conf')%}
{%- set service_conf_dir = salt['pillar.get']('supervisord:service_conf_dir') -%}

python-pip:
  pkg.installed

supervisor:
  pip.installed:
    - require:
      - pkg: python-pip

{{ service_conf_dir }}:
  file.directory:
    - mode: 755
    - makedirs: True
    - require:
      - pip: supervisor

{{ conf_file }}:
  file.managed:
    - source: salt://supervisord/files/supervisord.conf
    - mode: 644
    - template: jinjia
    - context:
      service_conf_dir: {{ service_conf_dir }}
    - require:
      - file: {{ service_conf_dir }}
