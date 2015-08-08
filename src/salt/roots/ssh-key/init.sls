{%- set ssh_keys = salt['pillar.get']('ssh:key_folder')%}
{%- set ci_key_file = salt['pillar.get']('ssh:ci_key_file')%}

{{ ssh_keys }}:
  file.recurse:
    - source: salt:/{{ ssh_keys }}
    - makedirs: True

{{ ssh_keys }}/{{ ci_key_file }}:
  file.managed:
    - mode: 600
    - require:
      - file: {{ ssh_keys }}
    - unless: test -f {{ ssh_keys }}/{{ ci_key_file }}
