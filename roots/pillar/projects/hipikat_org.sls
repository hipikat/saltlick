# Project (Salt Pillar) configuration for hipikat.org

{% from 'projects/hipikat_org-rewrites.sls' import hipikat_rewrites %}

# Return YAML configuration for the project based on arguments
{% macro hipikat_org() %}
  {% set fqdn = kwargs.get('fqdn', 'hipikat.org') %}
  {% set deploy_name = kwargs.get('name', 'hipikat.org') %}
  {{- deploy_name ~ ':' }}
    git_url: https://github.com/hipikat/hipikat.org.git
    rev: {{ kwargs.get('rev', 'master') }}
    admins:
      - hipikat
    requirements: etc/requirements.txt
    libdir: lib
    libs:
      django-cinch: https://github.com/hipikat/django-cinch.git
      feincms-elephantblog: https://github.com/hipikat/feincms-elephantblog.git
      django-revkom: https://github.com/hipikat/django-revkom.git
    port: {{ kwargs.get('port', 80) }}
    envdir: var/env
    env:
      DJANGO_SETTINGS_CLASS: {{ kwargs.get('settings', 'Production') }}
      DJANGO_ALLOWED_HOSTS: [{{ '.' ~ fqdn }}]
    pythonpaths:
      - src
      - etc
      - lib/django-cinch
      - lib/feincms-elephantblog
      - lib/django-revkom
    post_install:
      make_secret_key:
          run: scripts/make_secret_key.py > var/env/DJANGO_SECRET_KEY
          onlyif: 'file.absent: %cwd%/var/env/DJANGO_SECRET_KEY'
    wsgi_module: hipikat.wsgi
    settings_module: hipikat.settings
    run_uwsgi: {{ kwargs.get('run_uwsgi', true) }}
    enabled: {{ kwargs.get('enabled', true) }}
    watch: {{ kwargs.get('watch', false) }}
    watch_dirs: {{ kwargs.get('watch_dirs',  ['etc', 'lib', 'src', 'var/env']) }}
    http_basic_auth: {{ kwargs.get('http_basic_auth', false) }}
    servers:
      {{ fqdn }}:
        return: 301 http://www.{{ fqdn }}$request_uri
      www.{{ fqdn }}:
        locations:
          '/':
            directives:
              {{ hipikat_rewrites()|indent(14) }}
            pass_upstream: true
          '/media':
            alias: var/media
          '/static':
            alias: var/static
      blog.{{ fqdn }}:
        locations:
          '/':
            pass_upstream: true
{% endmacro %}

{% macro watch_dirs() %}
- 'etc'
- 'lib'
- 'src'
- 'var/env'
{% endmacro %}
