{%- set ldap_port = salt['pillar.get']('ldap:port') -%}
{%- set ldap_image = salt['pillar.get']('docker:registry') + '/slapd' -%}
{%- set image_version = salt['pillar.get']('ldap:image_version') -%}
{%- set env_domain = salt['pillar.get']('base:domain_name') -%}
{%- set env_org = salt['pillar.get']('base:domain_name') -%}
{%- set env_admin_pass = salt['pillar.get']('ldap:ldap_admin_pass')-%}
{%- set vol_data = salt['pillar.get']('ldap:data_volume') -%}
{%- set vol_conf = salt['pillar.get']('ldap:config_volume') -%}

include:
  - docker

ldap.image:
  docker.pulled:
    - name: {{ ldap_image }}
    - tag: {{ image_version }}
    - insecure_registry: True
    - require:
      - sls: docker

ldap.run:
  docker.running:
    - name: ldap-server
    - image: '{{ ldap_image }}'
    - ports:
      - 389/tcp: 
          HostIp: ""
          HostPort: {{ ldap_port }}
    - environment:
        "LDAP_DOMAIN": '{{ env_domain }}'
        "LDAP_ORGANISATION": '{{ env_org }}'
        "LDAP_ADMIN_PASSWORD": '{{ env_admin_pass }}'
        "LDAP_ROOTPASS": '{{ env_admin_pass }}'
        "SERVER_NAME": 'ldap'
    - volumes:
      - {{ vol_data }}: /var/lib/ldap
      - {{ vol_conf }}: /etc/ldap/slapd.d
    - require:
      - docker: ldap.image

