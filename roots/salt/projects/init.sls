# Standardised setup for (currently just Django) projects.
##########################################################

### Django projects
### Basic stack: Nginx + uWSGI + Virtualenv + Supervisord

{% if pillar.get('django_projects') %}

# Python and web server setup
include:
  - python
  - nginx

/etc/nginx/uwsgi_params:
  file.managed:
    - source: salt://projects/templates/uwsgi_params
    - mode: 444

# TODO: Let projects specify system package requirements.
# First line is for pillow.
# Second line's for postgresql.
# Third-line's for uWSGI routing support.
# Supervisor is used to manage uWSGI processes.
# apache2-utils is requied to generate htpasswd files.
{% set postgres_pkg = 'postgresql-9.1' %}
{% for system_pkg in (
  'python-dev', 'python-setuptools',
  postgres_pkg, 'python-psycopg2', 'libpq-dev',
  'libssl-dev', 'libpcre3-dev',
  'supervisor',
  'apache2-utils',
) %}
{{ system_pkg }}:
  pkg.installed
{% endfor %}

{% endif %}


### The projects
{% for deploy_name, project in pillar.get('django_projects', {}).items() %}

# Source (git) checkout
{{ deploy_name }}-checkout:
  git.latest:
    - name: {{ project.git_url }}
    {% if 'rev' in project %}
    - rev: {{ project['rev'] }}
    {% endif %} 
    - target: /opt/proj/{{ deploy_name }}

/opt/proj/{{ deploy_name }}:
  file.directory:
    - user: www-data
    - group: www-data
    - recurse:
      - user
      - group

# Virtualenv
/opt/venv/{{ deploy_name }}:
  virtualenv.managed:
    {% if 'requirements' in project %}
    - requirements: /opt/proj/{{ deploy_name }}/{{ project.requirements }}
    {% endif %}
  require:
    - pip.installed: virtualenv

# Virtualenvwrapper association between project & virtualenv
/opt/venv/{{ deploy_name }}/.project:
  file.managed:
    - mode: 444
    - contents: /opt/proj/{{ deploy_name }}

# Database and database user
{{ deploy_name }}:
{% for obj in ('database', 'user'): %}
  postgres_{{ obj }}:
    - present
    - require:
      - pkg: {{ postgres_pkg }}
{% endfor %}

# Envdir (flat files whose names/contents form environment keys/values)
{% if 'envdir' in project and 'env' in project: %}
{% for key, value in project['env'].iteritems(): %}
/opt/proj/{{ deploy_name }}/{{ project['envdir'] }}/{{ key }}:
  file.managed:
    - mode: 444
    - contents: {{ value }}
{% endfor %}
{% endif %}

# Python paths
{% if 'pythonpaths' in project %}
# TODO: This currently just assumes python2.7. Fix it.
/opt/venv/{{ deploy_name }}/lib/python2.7/site-packages/_django_project_paths.pth:
  file.managed:
    - source: salt://projects/templates/pythonpath_config.pth
    - mode: 444
    - template: jinja
    - context:
        base_dir: /opt/proj/{{ deploy_name }}
        paths: {{ project['pythonpaths'] }}
{% endif %}

# Additional libraries required by the project, sourced via git
{% if 'libdir' in project and 'libs' in project: %}
{% for dest, git_url in project['libs'].iteritems(): %}
{{ deploy_name }}-lib-{{ dest }}:
  git.latest:
    - name: {{ git_url }}
    - target: /opt/proj/{{ deploy_name }}/{{ project['libdir'] }}/{{ dest }}
{% endfor %}
{% endif %}

# Post-install hooks
# TODO: Work out why the hell the onlyif clause isn't working.
{% if 'post_install' in project: %}
{% for hook_name, hook in project['post_install'].iteritems(): %}
{% set cwd = '/opt/proj/' ~ deploy_name %}
{{ deploy_name }}-post_install-{{ hook['run'] }}:
  cmd.run:
    - cwd: {{ cwd }}
    - name: {{ hook['run'] }}
    - user: root
{% if 'onlyif' in hook %}
    - onlyif:
      - {{ hook['onlyif']|replace('%cwd%', cwd) }}
{% endif %}
{% endfor %}
{% endif %}

# Supervisor uWSGI task
{% if 'wsgi_module' in project: %}
{{ deploy_name }}-pip-uwsgi:
  pip.installed:
    - name: uWSGI
    - bin_env: /opt/venv/{{ deploy_name }}/bin/pip

/etc/supervisor/conf.d/{{ deploy_name }}.conf:
  file.managed:
    - source: salt://projects/templates/supervisor-uwsgi.conf
    - mode: 444
    - template: jinja
    - context:
        program_name: {{ deploy_name }}
        uwsgi_bin: /opt/venv/{{ deploy_name }}/bin/uwsgi
        uwsgi_ini: /opt/venv/{{ deploy_name }}/etc/uwsgi.ini

/opt/venv/{{ deploy_name }}/etc:
  file.directory:
    - mode: 755

/opt/venv/{{ deploy_name }}/var/log:
  file.directory:
    - makedirs: True

/opt/venv/{{ deploy_name }}/var:
  file.directory:
    - user: www-data
    - mode: 770
    - recurse:
      - user
      - mode

/opt/venv/{{ deploy_name }}/etc/uwsgi.ini:
  file.managed:
    - source: salt://projects/templates/uwsgi-master.ini
    - mode: 444
    - makedirs: True
    - template: jinja
    - context:
        basicauth: {{ project.get('http_basic_auth', false) }}
        realm: {{ deploy_name }}
        htpasswd_file: /opt/venv/{{ deploy_name }}/etc/{{ deploy_name }}.htpasswd
        socket: /opt/venv/{{ deploy_name }}/var/uwsgi.sock
        wsgi_module: {{ project['wsgi_module'] }}
        settings_module: {{ project['settings_module'] }}
        virtualenv: /opt/venv/{{ deploy_name }}
        uwsgi_log: /opt/var/{{ deploy_name }}/var/log/uwsgi.log

supervisor-update-{{ deploy_name }}:
  module.wait:
    - name: supervisord.update
    - watch:
      - file: /etc/supervisor/conf.d/{{ deploy_name }}.conf

run-{{ deploy_name }}-uwsgi:
  supervisord:
    - name: {{ deploy_name }}
    {% if 'run_uwsgi' in project and project['run_uwsgi']: -%}
    - running
    {%- else -%}
    - dead
    {%- endif %}

# Nginx hook-up
/etc/nginx/sites-available/{{ deploy_name }}.conf:
  file.managed:
    - source: salt://projects/templates/nginx-uwsgi-proxy.conf
    - mode: 444
    - template: jinja
    - context:
        project_name: {{ deploy_name }}
        project_root: /opt/proj/{{ deploy_name }}
        upstream_server: unix:///opt/proj/{{ deploy_name }}/var/uwsgi.sock
        port: {{ project['port'] }}
        servers: {{ project['servers'] }}
        http_basic_auth: {{ project.get('http_basic_auth', false) }}

{% if project.get('enabled', false) %}
{{ deploy_name }}-nginx:
  service.running:
    - name: nginx
    - reload: True
    - watch:
      - file: /etc/nginx/sites-enabled/{{ deploy_name }}.conf
  file.symlink:
    - name: /etc/nginx/sites-enabled/{{ deploy_name }}.conf
    - target: /etc/nginx/sites-available/{{ deploy_name }}.conf
{% endif %}

# HTTP Basic Authentication
{% if project.get('http_basic_auth', false) %}
{% for user in project.get('admins', []) %}
{{ deploy_name }}-{{ user }}-http_basic_auth:
  file.append:
    - name: /opt/venv/{{ deploy_name }}/etc/{{ deploy_name }}.htpasswd
    - text: {{ user }}:{{ pillar['users'][user]['htpasswd'] }}
    - makedirs: true
{% endfor %}

/opt/venv/{{ deploy_name }}/etc/{{ deploy_name }}.htpasswd:
  file.managed:
    - owner: www-data
    - mode: 440
{% endif %}


{% endif %}   # End if 'wsgi_module' in project

{% endfor %}  # End for deploy_name, project in django_projects
