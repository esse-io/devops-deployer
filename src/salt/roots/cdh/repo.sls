
{%- set base_url = salt['pillar.get']('cdh:repo_baseurl') -%}
{%- set gpg_key =  salt['pillar.get']('cdh:repo_gpgkey') -%}

cdh.repo:
  file.managed:
    - name: /etc/yum.repos.d/cdh.repo
    - source: salt://cdh/files/cdh.repo
    - template: jinja
    - mode: 644
    - context:
      repo_baseurl: {{ base_url }}
      repo_gpgkey: {{ gpg_key }}

cdh.repo.key:
  cmd.run:
    - name: rpm --import {{ gpg_key }}
    - require:
      - file: cdh.repo
