include:
  - graphite.supervisor

{%- from 'graphite/settings.sls' import graphite with context %}

install-deps:
  pkg.installed:
    - names:
      - memcached
      - python-pip
      - nginx
      - gcc
      - libmysqlclient-dev
      - python-dev
      - sqlite3
      - libcairo2
      - libcairo2-dev
      - python-cairo
      - pkg-config
      - gunicorn
  pip.installed:
    - names:
      - MySQL-python
      - daemonize
      - django==1.5
      - django-tagging
      - python-memcached
      - whisper
      - carbon
      - graphite-web

/opt/graphite/webapp/graphite/app_settings.py:
  file.append:
    - text: SECRET_KEY = '34960c411f3c13b362d33f8157f90d958f4ff1494d7568e58e0279df7450445ec496d8aaa098271e'

graphite:
  user.present:
    - group: graphite
    - shell: /bin/false

/opt/graphite/storage:
  file.directory:
    - user: graphite
    - group: graphite
    - recurse:
      - user
      - group

{{ graphite.whisper_dir }}:
  file.directory:
    - user: graphite
    - group: graphite
    - makedirs: True
    - recurse:
      - user
      - group

{%- if graphite.whisper_dir != graphite.prefix + '/storage/whisper' %}

{{ graphite.prefix + '/storage/whisper' }}:
  file.symlink:
    - target: {{ graphite.whisper_dir }}
    - force: True

{%- endif %}

local-dirs:
  file.directory:
    - user: graphite
    - group: graphite
    - names:
      - /var/run/gunicorn-graphite
      - /var/log/gunicorn-graphite
      - /var/run/carbon
      - /var/log/carbon

/opt/graphite/webapp/graphite/local_settings.py:
  file.managed:
    - source: salt://graphite/files/local_settings.py
    - template: jinja
    - context:
      dbtype: {{ graphite.dbtype }}
      dbname: {{ graphite.dbname }}
      dbuser: {{ graphite.dbuser }}
      dbpassword: {{ graphite.dbpassword }}
      dbhost: {{ graphite.dbhost }}
      dbport: {{ graphite.dbport }}

# django database fixtures
{{ graphite.prefix }}/webapp/graphite/initial_data.yaml:
  file.managed:
    - source: salt://graphite/files/initial_data.yaml
    - template: jinja
    - context:
      admin_email: {{ graphite.admin_email }}
      admin_user: {{ graphite.admin_user }}
      admin_password: {{ graphite.admin_password }}

/opt/graphite/conf/storage-schemas.conf:
  file.managed:
    - source: salt://graphite/files/storage-schemas.conf

/opt/graphite/conf/storage-aggregation.conf:
  file.managed:
    - source: salt://graphite/files/storage-aggregation.conf

/opt/graphite/conf/carbon.conf:
  file.managed:
    - source: salt://graphite/files/carbon.conf
    - template: jinja
    - context:
      graphite_port: {{ graphite.port }}
      graphite_pickle_port: {{ graphite.pickle_port }}
      max_creates_per_minute: {{ graphite.max_creates_per_minute }}
      max_updates_per_second: {{ graphite.max_updates_per_second }}

{%- if graphite.dbtype == 'sqlite3' %}

/opt/graphite/storage/graphite.db:
  file.managed:
    - source: salt://graphite/files/graphite.db
    - replace: False
    - user: graphite
    - group: graphite
  cmd.wait:
    - cwd: {{ graphite.prefix }}/webapp/graphite
    - name:  python manage.py syncdb --noinput
    - watch:
        - file: /opt/graphite/storage/graphite.db

{%- endif %}

/etc/supervisor/conf.d/graphite.conf:
  file.managed:
    - source: salt://graphite/files/supervisord-graphite.conf
    - mode: 644
  service.running:
    - name: supervisor
    - watch:
      - file: /etc/supervisor/conf.d/graphite.conf

/etc/nginx/sites-enabled/graphite.conf:
  file.managed:
    - source: salt://graphite/files/graphite.conf.nginx
    - template: jinja
    - context:
      graphite_host: {{ graphite.host }}
  service.running:
    - name: nginx
    - enable: True
    - reload: True
    - watch:
      - file: /etc/nginx/sites-enabled/graphite.conf
