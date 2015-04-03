{% from "graphite/map.jinja" import graphite with context %}

graphite:
  user.present:
    - group: graphite
    - shell: /bin/false

local-dirs:
  file.directory:
    - group: graphite
    - mode: 775
    - makedirs: True
    - names:
      - /var/log/carbon
      - /opt/graphite/storage
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
    - value: /opt/graphite/lib
  pip.installed:
    - name: carbon

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
          USER: graphite
        aggregator:
          STORAGE_DIR: {{graphite.storage_dir}}
          PID_DIR: /var/run/carbon/
          LOG_DIR: /var/log/carbon/
          USER: graphite

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



carbon-cache:
  file.managed:
    - name: /etc/init/carbon-cache.conf
    - source: salt://graphite/files/etc/init/carbon-daemon.jinja.conf
    - template: jinja
    - mode: 444
    - defaults:
        name: carbon-cache
  service.running:
    - require:
        - file: carbon-cache
        - pip: graphite-pip
    - watch:
        - file: /opt/graphite/conf/*

carbon-aggregator:
  file.managed:
    - name: /etc/init/carbon-aggregator.conf
    - source: salt://graphite/files/etc/init/carbon-daemon.jinja.conf
    - template: jinja
    - mode: 444
    - defaults:
        name: carbon-aggregator
  service.running:
    - require:
        - file: carbon-aggregator
        - pip: graphite-pip
    - watch:
        - file: /opt/graphite/conf/*
