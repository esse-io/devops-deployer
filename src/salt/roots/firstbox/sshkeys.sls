{%- set file_roots = salt['pillar.get']('base:salt:file_roots') %}
{%- set ssh_keys = file_roots + '/' + salt['pillar.get']('ssh:key_folder')%}
{%- set key_file = salt['pillar.get']('ssh:ci_key_file')%}

{{ ssh_keys }}:
  file.directory:
    - mode: 755
    - makedirs: True

sshkey.generate:
  cmd.run:
    - name: ssh-keygen -f {{ key_file }} -t rsa -N ''
    - cwd: {{ ssh_keys }}
    - unless: test -f {{ ssh_keys }}/{{ key_file }}.pub
    - require:
      - file: {{ ssh_keys }}
