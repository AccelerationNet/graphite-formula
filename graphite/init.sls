include:
  - graphite.supervisor

{% from "graphite/map.jinja" import graphite with context %}

graphite:
  user.present:
    - group: graphite
    - shell: /bin/false

local-dirs:
  file.directory:
    - user: graphite
    - group: graphite
    - makedirs: True
    - names:
      - /var/run/gunicorn-graphite
      - /var/log/gunicorn-graphite
      - /var/run/carbon
      - /var/log/carbon
      - {{graphite.storage_dir}}

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

# these install in non-standard locations, so needs additional
# config
graphite-pip:
  # tell pip to look in non-standard install locations
  environ.setenv: # `pip.install env_vars` doesn't seem to be working
    - name: PYTHONPATH
    - value: /opt/graphite/lib:/opt/graphite/webapp
  pip.installed:
    - names: [carbon, graphite-web]

# /opt/graphite/conf/storage-aggregation.conf:
#   file.managed:
#     - source: salt://graphite/files/storage-aggregation.conf

/opt/graphite/conf/carbon.conf:
  file.copy:
    - name: /opt/graphite/conf/carbon.conf
    - source: /opt/graphite/conf/carbon.conf.example
  ini.options_present:
    - sections:
        cache:
          STORAGE_DIR: {{graphite.storage_dir}}
          LOCAL_DATA_DIR: {{graphite.storage_dir}}/whisper
          PID_DIR: /var/run/carbon/
          LOG_DIR: /var/log/carbon/
          MAX_UPDATES_PER_SECOND: {{ graphite.max_updates_per_second }}
          MAX_CREATES_PER_MINUTE: {{ graphite.max_creates_per_minute }}
        aggregator:
          STORAGE_DIR: {{graphite.storage_dir}}
          PID_DIR: /var/run/carbon/
          LOG_DIR: /var/log/carbon/

/opt/graphite/conf/storage-schemas.conf:
  file.managed: []
  ini.sections_present:
    - sections:
{% for rule, ruledef in graphite.retentions.items() %}
        {{rule}}:
          pattern: {{ruledef['pattern']}}
          retentions: {{ruledef['retentions']}}
{% endfor %}
        default:
          pattern: .*
          retentions: {{ graphite.default_retention }}

/opt/graphite/conf/graphite-web.py:
  file.managed:
    - source: salt://graphite/files/local_settings.py
    - template: jinja
    - context:
        STORAGE_DIR: {{ graphite.storage_dir }}
        TIME_ZONE: {{ salt['timezone.get_zone']() }}
        extras: {{ graphite.local_settings | yaml }}

/opt/graphite/webapp/graphite/local_settings.py:
  file.symlink:
    - target: /opt/graphite/conf/graphite-web.py
    - force: True
    - require:
        - file: /opt/graphite/conf/graphite-web.py

graphite.db:
  cmd.wait:
    - cwd: /opt/graphite/webapp/graphite
    - name:  python manage.py syncdb --noinput
    - watch:
        - pip: graphite-pip
    - require:
        - file: /opt/graphite/webapp/graphite/local_settings.py
  file.managed:
    - name: {{graphite.storage_dir}}/graphite.db
    - user: graphite
    - group: graphite
    - watch:
        - cmd: graphite.db

/etc/supervisor/conf.d/graphite.conf:
  file.managed:
    - source: salt://graphite/files/supervisord-graphite.conf
    - mode: 644
  service.running:
    - name: supervisor
    - resart: True
    - watch:
      - file: /etc/supervisor/conf.d/graphite.conf
      - file: /opt/graphite/conf/*
      - ini: /opt/graphite/conf/*

/etc/nginx/sites-enabled/graphite.conf:
  file.managed:
    - source: salt://graphite/files/graphite.conf.nginx
    - template: jinja
    - context:
        server_name: {{ graphite.server_name }}
  service.running:
    - name: nginx
    - enable: True
    - reload: True
    - watch:
      - file: /etc/nginx/sites-enabled/graphite.conf
