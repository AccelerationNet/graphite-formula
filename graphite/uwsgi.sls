{% from "graphite/map.jinja" import graphite with context %}

include:
  - graphite

/opt/graphite/webapp/graphite/local_settings.py:
  file.managed:
    - source: salt://graphite/files/opt/graphite/webapp/graphite/local_settings.py
    - template: jinja
    - defaults:
        time_zone: {{ salt['timezone.get_zone']() }}
        # TODO: use
        # http://docs.saltstack.com/en/latest/ref/modules/all/salt.modules.grains.html#salt.modules.grains.get_or_set_hash
        # when it's fixed
        secret_key: {{ salt['key.finger']() }}
        local_settings: ''
    - context: {{ graphite | yaml}}

graphite.db:
  cmd.wait:
    - cwd: /opt/graphite/webapp/graphite
    - name:  python manage.py syncdb --noinput
    - watch:
        - pip: graphite-pip
        - file: /opt/graphite/webapp/graphite/local_settings.py
  file.managed:
    - name: {{graphite.storage_dir}}/graphite.db
    - replace: False
    - user: www-data
    - group: graphite
    - watch:
        - cmd: graphite.db

uwsgi:
  # tell pip to look in non-standard install locations
  environ.setenv: # `pip.install env_vars` doesn't seem to be working
    - name: PYTHONPATH
    - value: /opt/graphite/lib:/opt/graphite/webapp
  pip.installed:
    - names:
        - uwsgi
        - graphite-web
  file.directory:
    - user: www-data
    - makedirs: True
    - names:
      - /var/log/graphite
      - /opt/graphite/storage
      - {{graphite.storage_dir}}

# wsgi.py
/opt/graphite/conf/wsgi.py:
  file.copy:
    - source: /opt/graphite/conf/graphite.wsgi.example
    - require:
        - pip: uwsgi

# uwsgi ini file
/opt/graphite/conf/graphite.ini:
  file.managed:
    - source: salt://graphite/files/opt/graphite/conf/graphite.ini
    - mode: 444
    - require:
        - pip: uwsgi

# service
graphite-service:
  file.managed:
    - name: /etc/init/graphite.conf
    - source: salt://graphite/files/etc/init/graphite.conf
    - mode: 444
  service.running:
    - name: graphite
    - require:
        - file: graphite-service
        - file: /opt/graphite/conf/graphite.ini
    - watch:
        - file: /opt/graphite/*

# nginx includes
/etc/nginx/graphite-uwsgi.conf:
  file.managed:
    - source: salt://graphite/files/etc/nginx/graphite-uwsgi.conf
    - makedirs: True
    - mode: 444
