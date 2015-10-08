
{%- set docker_image = salt['pillar.get']('docker:registry') + '/gerrit' -%}
{%- set image_version = salt['pillar.get']('gerrit:image_version') -%}
{%- set httpd_port = salt['pillar.get']('gerrit:httpd_port') -%}
{%- set ssh_port = salt['pillar.get']('gerrit:ssh_port') -%}
{%- set domain_name = salt['pillar.get']('base:domain_name') -%}
{%- set postgres_container = salt['pillar.get']('postgresql:container_name') -%}
{%- set replicate_key_name = salt['pillar.get']('ssh:ci_key_file') -%}
{%- set replcate_user = salt['pillar.get']('base:ci_user') -%}
{%- set vol_data = salt['pillar.get']('gerrit:data_volume') -%}
{%- set vol_ssh_keys = salt['pillar.get']('ssh:key_folder') -%}
{%- set db_name = salt['pillar.get']('postgresql:gerrit_db_name') -%}
{%- set ldap_dn = salt['pillar.get']('base:domain_name').split('.') -%}
{%- set gerrit_weburl = salt['pillar.get']('base:gerrit_weburl', '') -%}
{%- set httpd_listenurl = salt['pillar.get']('base:gerrit_httpd_listenurl', '') -%}
{%- set gitlab_ssh_port = salt['pillar.get']('gitlab:ssh_port') -%}
{%- set get_net_info = salt['util.getNodeNetworks'] -%}

{%- set ldap_ip_dict = salt['mine.get']('roles:ldap-server', 'grains.item', expr_form='grain') -%}
{%- set gerrit_ip_dict = salt['mine.get']('roles:gerrit', 'grains.item', expr_form='grain') -%}
{%- set gitlab_ip_dict = salt['mine.get']('roles:gitlab', 'grains.item', expr_form='grain') -%}

{%- if ldap_ip_dict | length !=0 %}
{%- set ldap_ip = get_net_info(ldap_ip_dict.keys()[0])['ipaddr'] %}
{%- else -%}
{%- set ldap_ip = '' %}
{%- endif -%}

{%- if gerrit_ip_dict | length !=0 %}
{%- set gerrit_ip = get_net_info(gerrit_ip_dict.keys()[0])['ipaddr'] %}
{%- else -%}
{%- set gerrit_ip = '' %}
{%- endif -%}

{%- if gitlab_ip_dict | length !=0 %}
{%- set gitlab_ip = get_net_info(gitlab_ip_dict.keys()[0])['ipaddr'] %}
{%- else -%}
{%- set gitlab_ip = '' %}
{%- endif -%}

include:
  - docker
  - ssh-key
  - postgresql

gerrit.image:
  docker.pulled:
    - name: {{ docker_image }}
    - tag: {{ image_version }}
    - insecure_registry: True
    - require:
      - sls: docker

gerrit.run:
  docker.running:
    - name: gerrit
    - image: {{ docker_image }}:{{ image_version }}
    - ports:
      - 8080/tcp: 
          HostIp: ""
          HostPort: {{ httpd_port }}
      - 29418/tcp: 
          HostIp: ""
          HostPort: {{ ssh_port }}
    - environment:
        {%- if gerrit_weburl == '' %}
        'WEBURL': http://{{ gerrit_ip }}:{{ httpd_port }}
        {% else %}
        'WEBURL': {{ gerrit_weburl }}
        {% endif %}
        {%- if httpd_listenurl != '' %}
        'HTTPD_LISTENURL': {{ httpd_listenurl }}
        {% endif %}
        'DATABASE_TYPE': 'postgresql'
        'DB_ENV_DB_NAME': {{ db_name }}
        'AUTH_TYPE': 'LDAP'
        'LDAP_SERVER': {{ ldap_ip }}
        'LDAP_ACCOUNTBASE': ou=people,dc={{ ldap_dn[0] }},dc={{ ldap_dn[1] }}
        'LDAP_ACCOUNTPATTERN': '(mail=${username})'
        'LDAP_ACCOUNTFULLNAME': 'displayName'
        'LDAP_ACCOUNTEMAILADDRESS': 'mail'
        'LDAP_REFERRAL': 'follow'
        'REPLICATE_ENABLED': 'true'
        'REPLICATE_USER': git
        'REPLICATE_KEY': {{ replicate_key_name }}
        'REPLICATE_SERVER': {{ gitlab_ip }}
        'RP_SERVER_PORT': {{ gitlab_ssh_port }}
    - volumes:
      - {{ vol_data }}: /home/git/data
    - volumes:
      - {{ vol_data }}: /var/gerrit/review_site
      - {{ vol_ssh_keys }}: /var/gerrit/.ssh
    - links:
        {{ postgres_container }}: db
    - require:
      - sls: postgresql
      - sls: ssh-key
      - docker: gerrit.image
