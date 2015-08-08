{%- set docker_image = salt['pillar.get']('docker:registry') + '/phpldapadmin' -%}
{%- set php_port = salt['pillar.get']('php_ldap_admin:port') -%}
{%- set image_version = salt['pillar.get']('php_ldap_admin:image_version') -%}
{%- set get_net_info = salt['util.getNodeNetworks'] -%}
{%- set vol_ssl = salt['pillar.get']('ssl:key_folder') -%}
{%- set env_ssl_key = salt['pillar.get']('ssl:key_file') -%}
{%- set env_ssl_crt = salt['pillar.get']('ssl:crt_file') -%}

{%- set ldap_ip_dict = salt['mine.get']('roles:ldap-server', 'grains.item', expr_form='grain') -%}
{%- if ldap_ip_dict | length !=0 %}
{%- set ldap_ip = get_net_info(ldap_ip_dict.keys()[0])['ipaddr'] %}
{%- else -%}
{%- set ldap_ip = '' %}
{%- endif -%}

include:
  - docker
  - ssl-key

php-ldap-admin.image:
  docker.pulled:
    - name: {{ docker_image }}
    - tag: {{ image_version }}
    - insecure_registry: True
    - require:
      - sls: docker

php-ldap-admin.run:
  docker.running:
    - name: phpldapadmin
    - image: '{{ docker_image }}'
    - ports:
      - 443/tcp:
          HostIp: ""
          HostPort: {{ php_port }}
    - environment:
        "LDAP_HOSTS": '{{ ldap_ip }}'
        "SSL_KEY_FILENAME": '{{ env_ssl_key }}'
        "SSL_CRT_FILENAME": '{{ env_ssl_crt }}'
    - volumes:
      - {{ vol_ssl }}: /osixia/phpldapadmin/apache2/ssl 
    - require:
      - docker: php-ldap-admin.image
      - sls: ssl-key

