{%- set ssl_keys = salt['pillar.get']('ssl:key_folder')%}
{%- set key_file = salt['pillar.get']('ssl:key_file')%}

{{ ssl_keys }}:
  file.recurse:
    - source: salt:/{{ ssl_keys }}
    - makedirs: True

{{ ssl_keys }}/{{ key_file }}:
  file.managed:
    - mode: 400
    - require:
      - file: {{ ssl_keys }}
    - unless: test -f {{ ssl_keys }}/{{ key_file }}
