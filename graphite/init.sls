{% from "graphite/map.jinja" import graphite with context %}

include:
  - graphite.supervisor

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
      - pytz

# these install in non-standard locations, so needs additional
# config
graphite-pip:
  # tell pip to look in non-standard install locations
  environ.setenv: # `pip.install env_vars` doesn't seem to be working
    - name: PYTHONPATH
    - value: /opt/graphite/lib:/opt/graphite/webapp
  pip.installed:
    - names: [carbon, graphite-web]

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

/opt/graphite/storage:
  file.directory:
    - user: graphite
    - require:
        - pip: graphite-pip
        - user: graphite


/opt/graphite/webapp/graphite/local_settings.py:
  file.managed:
    - source: salt://graphite/files/local_settings.py
    - template: jinja
    - defaults:
        time_zone: {{ salt['timezone.get_zone']() }}
        # TODO: use
        # http://docs.saltstack.com/en/latest/ref/modules/all/salt.modules.grains.html#salt.modules.grains.get_or_set_hash
        # when it's fixed
        secret_key: {{ salt['key.finger']() }}
        use_nginx_auth: False
        local_settings: ''
    - context: {{ graphite | yaml}}

{% if graphite.get('use_nginx_auth') %}
/opt/graphite/webapp/graphite/salt_custom.py:
  file.managed:
    - contents: |
        from django.contrib.auth.middleware import RemoteUserMiddleware

        class CustomHeaderMiddleware(RemoteUserMiddleware):
            header = 'HTTP_REMOTE_USER'

{% endif %}

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
      - file: /opt/graphite/webapp/*
      - file: /opt/graphite/conf/*
      - ini: /opt/graphite/conf/*

/etc/nginx/graphite-web.conf:
  file.managed:
    - source: salt://graphite/files/etc/nginx/graphite-web.conf
    - mode: 444
    - make_dirs: True
