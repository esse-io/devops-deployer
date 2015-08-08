{%- set docker_image = salt['pillar.get']('docker:registry') + '/jenkins' -%}
{%- set web_port = salt['pillar.get']('jenkins:web_port') -%}
{%- set master_port = salt['pillar.get']('jenkins:master_port') -%}
{%- set image_version = salt['pillar.get']('jenkins:image_version') -%}
{%- set vol_data = salt['pillar.get']('jenkins:data_volume') -%}
{%- set ssh_keys = salt['pillar.get']('ssh:key_folder') -%}
{%- set ci_key_file = salt['pillar.get']('ssh:ci_key_file')%}
{%- set opts = salt['pillar.get']('jenkins:additional_opts') -%}
{%- set ci_user = salt['pillar.get']('base:ci_user') -%}
{%- set domain_name = salt['pillar.get']('base:domain_name') -%}
{%- set gerrit_http_port = salt['pillar.get']('gerrit:httpd_port') -%}
{%- set nexus_repo = salt['pillar.get']('jenkins:nexus_repo') -%}
{%- set gerrit_weburl = salt['pillar.get']('base:gerrit_weburl', '') -%}
{%- set jenkins_weburl = salt['pillar.get']('base:jenkins_weburl', '') -%}

{%- set get_net_info = salt['util.getNodeNetworks'] -%}
{%- set ldap_ip_dict = salt['mine.get']('roles:ldap-server', 'grains.item', expr_form='grain') -%}
{%- set gerrit_ip_dict = salt['mine.get']('roles:gerrit', 'grains.item', expr_form='grain') -%}
{%- set jenkins_ip_dict = salt['mine.get']('roles:jenkins', 'grains.item', expr_form='grain') -%}
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

{%- if jenkins_ip_dict | length !=0 %}
{%- set jenkins_ip = get_net_info(jenkins_ip_dict.keys()[0])['ipaddr'] %}
{%- else -%}
{%- set jenkins_ip = '' %}
{%- endif -%}

include:
  - docker

jenkins.image:
  docker.pulled:
    - name: {{ docker_image }}
    - tag: {{ image_version }}
    - insecure_registry: True
    - require:
      - sls: docker

{# Ensure we have same uid with the docker container #}
jenkins:
  user.present:
    - uid: 1000

{{ vol_data }}:
  file.directory:
    - mode: 755
    - makedirs: True
    - user: jenkins
    - group: jenkins

jenkins.run:
  docker.running:
    - name: jenkins
    - image: {{ docker_image }}:{{ image_version }}
    - ports:
      - 8080/tcp: 
          HostIp: ""
          HostPort: {{ web_port }}
      - 50000/tcp: 
          HostIp: ""
          HostPort: {{ master_port }}
    - command: {{ opts }}
    - volumes:
      - {{ vol_data }}: /var/jenkins_home
    - require:
      - docker: jenkins.image
      - user: jenkins

jenkins.postconfig:
  cmd.script:
    - name: /tmp/setupJenkins.sh
    - source: salt://jenkins/files/setupJenkins.sh
    - template: jinja
    - mode: 644
    - cwd: /tmp
    - shell: /bin/bash
    - context:
      jenkins_container: jenkins
      ci_key: {{ ssh_keys }}/{{ ci_key_file }}
      ci_user: {{ ci_user }}
      domain_name: {{ domain_name }}
      gerrit_name: {{ gerrit_ip }}
      gerrit_ssh_host: {{ gerrit_ip }}
      {% if gerrit_weburl == '' %}
      'gerrit_weburl': http://{{ gerrit_ip }}:{{ gerrit_http_port }}
      {% else %}
      'gerrit_weburl': {{ gerrit_weburl }}
      {% endif %}
      {% if jenkins_weburl == '' %}
      jenkins_weburl: http://{{ jenkins_ip }}:{{ web_port }}/jenkins
      {% else %}
      'jenkins_weburl': {{ jenkins_weburl }}
      {% endif %}
      nexus_repo: {{ nexus_repo }}
    - require:
      - docker: jenkins.run   

