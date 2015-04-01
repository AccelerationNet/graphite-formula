{% from "graphite/map.jinja" import graphite with context %}

include:
  - graphite

nginx:
  pkg.installed: []

/etc/nginx/sites-enabled/{{ graphite.server_name }}.conf:
  file.managed:
    - source: salt://graphite/files/etc/nginx/sites-enabled/graphite.conf
    - template: jinja
    - defaults:
        server_name: {{ graphite.server_name }}
    - require:
        - pkg: nginx
  service.running:
    - name: nginx
    - enable: True
    - reload: True
    - watch:
      - file: /etc/nginx/sites-enabled/*
