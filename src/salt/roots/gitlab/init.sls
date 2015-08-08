{%- set docker_image = salt['pillar.get']('docker:registry') + '/gitlab' -%}
{%- set image_version = salt['pillar.get']('gitlab:image_version') -%}
{%- set ssh_port = salt['pillar.get']('gitlab:ssh_port') -%}
{%- set ssl_port = salt['pillar.get']('gitlab:ssl_port') -%}
{%- set get_net_info = salt['util.getNodeNetworks'] -%}
{%- set vol_data = salt['pillar.get']('gitlab:data_volume') -%}
{%- set env_ldap_pass = salt['pillar.get']('ldap:ldap_admin_pass') -%}
{%- set env_ldap_port = salt['pillar.get']('ldap:port') -%}
{%- set postgres_container = salt['pillar.get']('postgresql:container_name')-%}
{%- set redis_container = salt['pillar.get']('redis:container_name')-%}
{%- set ssl_keys = salt['pillar.get']('ssl:key_folder')%}
{%- set key_file = salt['pillar.get']('ssl:key_file')%}
{%- set crt_file = salt['pillar.get']('ssl:crt_file')%}
{%- set ldap_dn = salt['pillar.get']('base:domain_name').split('.') -%}
{%- set ldap_base = salt['pillar.get']('ldap:base') -%}
{%- set db_name = salt['pillar.get']('postgresql:gitlab_db_name') -%}

{%- set ldap_ip_dict = salt['mine.get']('roles:ldap-server', 'grains.item', expr_form='grain') -%}
{%- set gitlab_ip_dict = salt['mine.get']('roles:gitlab', 'grains.item', expr_form='grain') -%}
{%- if ldap_ip_dict | length !=0 %}
{%- set ldap_ip = get_net_info(ldap_ip_dict.keys()[0])['ipaddr'] %}
{%- else -%}
{%- set ldap_ip = '' %}
{%- endif -%}

{%- if gitlab_ip_dict | length !=0 %}
{%- set gitlab_ip = get_net_info(gitlab_ip_dict.keys()[0])['ipaddr'] %}
{%- else -%}
{%- set gitlab_ip = '' %}
{%- endif -%}

include:
  - docker
  - ssl-key
  - postgresql
  - redis

gitlab.image:
  docker.pulled:
    - name: {{ docker_image }}
    - tag: {{ image_version }}
    - insecure_registry: True
    - require:
      - sls: docker

gitlab.create.certs:
  file.directory:
    - name: {{ vol_data }}/certs
    - dir_mode: 755
    - makedirs: True
    - unless: test -d {{ vol_data }}/certs

gitlab.cp.certs:
  file.recurse:
    - name: {{ vol_data }}/certs
    - source: salt:/{{ ssl_keys }}
    - makedirs: True
    - require:
      - file: gitlab.create.certs

{{ vol_data }}/certs/{{ key_file }}:
  file.managed:
    - mode: 400
    - require:
      - sls: ssl-key
      - file: gitlab.cp.certs

gitlab.run:
  docker.running:
    - name: gitlab
    - image: {{ docker_image }}:{{ image_version }}
    - ports:
      - 443/tcp: 
          HostIp: ""
          HostPort: {{ ssl_port }}
      - 22/tcp: 
          HostIp: ""
          HostPort: {{ ssh_port }}
    - environment:
        'GITLAB_HOST': {{ gitlab_ip }}
        'GITLAB_PORT': {{ ssl_port }}
        'GITLAB_SSH_PORT': {{ ssh_port }}
        'GITLAB_HTTPS': 'true'
        'SSL_SELF_SIGNED': 'true'
        'GITLAB_HTTPS_HSTS_MAXAGE': 2592000
        'LDAP_ENABLED': 'true'
        'LDAP_PASS': '{{ env_ldap_pass }}'
        'LDAP_HOST': '{{ ldap_ip }}'
        'LDAP_PORT': {{ env_ldap_port }}
        'LDAP_UID': 'mail'
        'LDAP_BIND_DN': cn=admin,dc={{ ldap_dn[0] }},dc={{ ldap_dn[1] }}
        'LDAP_METHOD': plain
        'LDAP_BASE': {{ ldap_base }}
        'LDAP_ACTIVE_DIRECTORY': 'false'
        'LDAP_ALLOW_USERNAME_OR_EMAIL_LOGIN': 'false'
        'SSL_CERTIFICATE_PATH': /home/git/data/certs/{{ crt_file }}
        'SSL_KEY_PATH': /home/git/data/certs/{{ key_file }}
        'DB_NAME': {{ db_name }}
    - volumes:
      - {{ vol_data }}: /home/git/data
    - links:
        {{ postgres_container }}: postgresql
        {{ redis_container }}: redisio
    - require:
      - sls: postgresql
      - sls: redis
      - docker: gitlab.image
      - file: {{ vol_data }}/certs
