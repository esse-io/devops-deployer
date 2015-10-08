{%- from "docker/map.jinja" import docker with context %}
{%- set docker_registry = salt['pillar.get']('docker:registry') -%}
wget:
  pkg.installed

docker-rpm:
  file.managed:
    - name: /tmp/docker.rpm
    - source: {{ docker.download_url }}
    - source_hash: {{ docker.rpm_hash }}
    - require:
      - pkg: wget

{#
docker-pkgs:
  pkg.installed:
    - sources:
      - docker: {{ docker.download_url }}

#}

docker-install:
  cmd.script:
    - name: /tmp/docker_install.sh
    - source: salt://docker/files/{{ docker.install_script }}
    - template: jinja
    - mode: 644
    - cwd: /tmp
    - shell: /bin/bash
    - require:
      - file: docker-rpm   

python-setuptools:
  pkg.installed

python-pip:
  pkg.installed:
{#  cmd:
    - run
    - cwd : /
    - name: easy_install --script-dir=/usr/bin -U pip
    - reload_modules: true
#}
    - require:
      - pkg: python-setuptools

{#
Do not use the docker-py 1.3.0 to avoid following error:
docker.errors.InvalidVersion: mem_limit has been moved to host_config in API version 1.19
#}
docker-py==1.2.3:
  pip.installed:
    - require:
      - pkg: python-pip
    - reload_modules: true

netaddr:
  pip.installed:
    - require:
      - pkg: python-pip
    - reload_modules: true

docker-config:
  file.managed:
    - name: {{ docker.config_file }}
    - source: salt://docker/files/docker
    - template: jinja
    - mode: 644
    - context:
      docker_registry: {{ docker_registry }}
    - require:
      - cmd: docker-install

docker-service:
  service.running:
    - name: {{ docker.service }}
    - enable: True
    - reload: True
    - watch:
      - file: docker-config
