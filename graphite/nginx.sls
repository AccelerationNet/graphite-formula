{% from "graphite/map.jinja" import graphite with context %}

include:
  - graphite.uwsgi

nginx:
  pkg.installed: []

/etc/nginx/sites-enabled/{{ graphite.server_name }}.conf:
  file.managed:
    - source: salt://graphite/files/etc/nginx/sites-enabled/graphite.jinja.conf
    - template: jinja
    - defaults:
        server_name: {{ graphite.server_name }}
    - require:
        - pkg: nginx
  service.running:
    - name: nginx
    - watch:
      - file: /etc/nginx/sites-enabled/*
