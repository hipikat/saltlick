#!stateconf -o yaml . jinja
#
# Install Salt for development (I.e. from source, in a Virtualenv,
# which is also good for just keeping it separate from system-Python.)
# Currently this setup has only been tested on Ubuntu 14.10.
###########################################


{% set install_conf = pillar.get('saltlick', {}).get('salt_install', {}) %}


include:
  - saltlick.null

  {% if install_conf.get('launcher') == 'supervisor' and
        pillar.get('controllers', {}).get('supervisor') %}
  - {{ pillar.get('controllers', {}).get('supervisor') }}
  {% endif %}


.System packages required for development Salt:
  pkg.installed:
    - pkgs:
      # Required to pull Salt from GitHub
      - git
      # Taken from HACKING.rst in the Salt source (2015-02-15)
      - build-essential
      - libssl-dev
      - python-dev
      - python-m2crypto
      - python-pip
      - swig

.System-Python packages required for development Salt:
  pip.installed:
    - name: virtualenv

.Virtualenv for development Salt:
  virtualenv.managed:
    - name: /opt/salt
    # Debian and Ubuntu systems have modified openssl libraries and
    # mandate that a patched version of M2Crypto be installed. This
    # means that M2Crypto needs to be installed via apt ... This also
    # means that pulling in the M2Crypto installed using apt requires
    # using --system-site-packages when creating the virtualenv.
    # - http://docs.saltstack.com/en/latest/topics/development/hacking.html
    - system_site_packages: True

.Git checkout of Salt:
  git.latest:
    - name: https://github.com/saltstack/salt.git
    # TODO: Default to 'develop'? Configurable via settings?
    - rev: '{{ install_conf.get("rev", "develop") }}'
    - target: /opt/salt/salt
    - unless: test -d /opt/salt/salt

{# for salt_requires in ('dev_requirements_python27.txt', 'cloud-requirements.txt', 'zeromq-requirements.txt') #}
{% for salt_requires in ('dev_python27.txt',
                         'zeromq.txt') %}
.Salt requirements '{{ salt_requires }}', from Salt source:
  pip.installed:
    - requirements: /opt/salt/salt/requirements/{{ salt_requires }}
    - bin_env: /opt/salt
{% endfor %}

.Pip-install Salt requirement 'psutil', for ZeroMQ transport:
  pip.installed:
    - name: psutil
    - bin_env: /opt/salt

.Pip (editable) install of Salt source:
  pip.installed:
    - name: salt
    - bin_env: /opt/salt
    - editable: file:///opt/salt/salt

.Link main /opt/salt/bin/salt binary to /usr/local/bin:
  file.symlink:
    - name: /usr/local/bin/salt
    - target: /opt/salt/bin/salt

{% for salt_bin in ('api', 'call', 'cloud', 'cp', 'jenkins-build', 'key',
                    'master', 'minion', 'run', 'ssh', 'syndic', 'unity') %}
.Link binary file salt-{{ salt_bin }} to /usr/local/bin:
  file.symlink:
    - name: /usr/local/bin/salt-{{ salt_bin }}
    - target: /opt/salt/bin/salt-{{ salt_bin }}
{% endfor %}

.Salt configuration directory:
  file.directory:
    - name: /etc/salt
    - makedirs: True

{% for salt_role in ('master', 'minion') %}
.Default Salt {{ salt_role }} configuration file:
  file.copy:
    - name: /etc/salt/{{ salt_role }}
    - source: /opt/salt/salt/conf/{{ salt_role }}
    - unless: test -f /etc/salt/{{ salt_role }}
{% endfor %}

#.Point the minion at master ''
# TODO: Are we able to get the master's address??
# oooh, we should just get it from the pillar right?
# hmm we need something in Saltlick to cleanly change the master of a minion...

.Salt minion ID file:
  file.managed:
    - name: /etc/salt/minion_id
    - contents_grains: id
    - contents_newline: False

# Created by salt-minion when it is first run - but we may want to pre-seed?
#.Salt minion configuration directory:
#  file.directory:
#    - name: /etc/salt/minion.d
#    - makedirs: True


{% if install_conf.get('launcher') == 'supervisor' %}
  {% for salt_process in ('master', 'minion') %}
.Supervisor job configuration for 'salt-{{ salt_process }}':
  file.managed:
    - name: {{ pillar['settings']['supervisor_conf_dir'] }}/salt-{{ salt_process }}.ini
    - source: salt://saltlick/templates/salt-{{ salt_process }}-supervisor.ini
    - template: jinja
    - makedirs: True
  {% endfor %}
{% endif %}
