# NB: salt-managed; edits will be overwritten

MEMCACHE_HOSTS = ['127.0.0.1:11211']
SECRET_KEY = '{{ secret_key }}'
STORAGE_DIR = '{{ storage_dir }}'
LOG_DIR = '/var/log/graphite'
TIME_ZONE = '{{ time_zone }}'

{{ local_settings }}
