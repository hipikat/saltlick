# Python setup with system-wide pyenv, virtualenv, virtualenvwrapper, etc.
##########################################################################

# Install pip for system-Python.
python-pip:
  pkg.installed

# Install system-Python packages
{% for system_python_pkg in (
  'flake8',
  'virtualenv',
  'virtualenvwrapper',
  'yolk',
) %}
{{ system_python_pkg }}:
  pip.installed:
    - require:
      - pkg: python-pip
{% endfor %}

# Virtualenv and virtualenvwrapper.
# Users should `source /etc/profile.d/virtualenvwrapper.sh`.
{% for venv_dir in ('venv', 'proj') %}
/opt/{{ venv_dir }}:
  file.directory:
    - user: root
    - group: root
    - mode: 775
{% endfor %}

/etc/profile.d/virtualenvwrapper.sh:
  file:
    - managed
    - template: jinja
    - user: root
    - group: root
    - mode: 444 
    - source: salt://python/init_virtualenvwrapper.sh
    - require:
      - pip.installed: virtualenvwrapper
