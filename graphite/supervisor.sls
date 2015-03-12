{%- from 'graphite/settings.sls' import graphite with context %}

supervisor:
  pkg.installed:
    - name: supervisor
  file.directory:
    - names:
      - /etc/supervisor/conf.d
      - /var/log/supervisor
    - user: root
    - group: root
    - mode: 755
    - makedirs: True
  service.running:
    - name: supervisor
    - reload: True
    - enable: True
    - watch:
      - pkg: supervisor
