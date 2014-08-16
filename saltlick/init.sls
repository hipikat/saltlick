#!stateconf -o yaml . jinja
#
# Saltlick installs and configures Salt masters
###########################################

{% set saltlick = pillar.get('saltlick', {}) %}


# Set group-write on Salt files and directories if a Salt group is specified
{% set salt_user = saltlick.get('salt_user', 'root') %}
{% set salt_group = saltlick.get('salt_group', 'root') %}

{% if 'file_mode' in saltlick %}
  {% set file_mode = saltlick['file_mode'] %}
{% elif 'salt_group' in saltlick %}
  {% set file_mode = '664' %}
.Salt group:
  group.present:
    - name: {{ saltlick['salt_group'] }}
{% else %}
  {% set file_mode = '644' %}
{% endif %}

{% if 'dir_mode' in saltlick %}
  {% set dir_mode = saltlick['dir_mode'] %}
{% elif file_mode == '664' %}
  {% set dir_mode = '775' %}
{% else %}
  {% set dir_mode = '755' %}
{% endif %}


# Require apache-libcloud if salt-cloud is enabled on this minion. This
# # will have already been done if -L and -P were passed to bootstrap-salt.sh.
{% if saltlick.get('salt_cloud') %}
.Salt Cloud system packages:
  pkg.installed:
    - name: python-pip

.Salt Cloud system-Python packages:
  pip.installed:
    - name: apache-libcloud
{% endif %}


# Install Salt roots and pillars
{% for part in ('roots', 'pillars') %}
  {% set salt_part = saltlick.get('salt_' ~ part) %}
  {% if salt_part %}
    {% if salt_part is not mapping %}
      {% set salt_part = {'url': salt_part} %}
    {% endif %}

.Salt {{ part }} git checkout:
  git.latest:
    - name: {{ salt_part['url'] }}
    - rev: {{ salt_part.get('rev', 'master') }}
    {% if part == 'roots' %}
    - target: /srv/salt
    {% elif part == 'pillars' %}
    - target: /srv/pillar
    {% endif %}
    - force: {{ salt_part.get('force', true) }}

  {% endif %}
{% endfor %}


# Install Salt formulas
{% set formulas = saltlick.get('salt_formulas', {}) %}
{% for formula_name, formula_spec in formulas.items() %}
  {% if formula_spec is not mapping %}
    {% set formula_spec = {'url': formula_spec} %}
  {% endif %}

.Formula {{ formula_name }} git checkout:
  git.latest:
    - name: {{ formula_spec['url'] }}
    - rev: {{ formula_spec.get('rev', 'master') }}
    - target: /srv/formulas/{{ formula_name }}-formula
    - force: {{ formula_spec.get('force', true) }}

.Formula {{ formula_name }} symlink into Salt roots:
  file.symlink:
    - name: /srv/salt/{{ formula_name }}
    - target: /srv/formulas/{{ formula_name }}-formula/{{ formula_name }}
    - user: {{ salt_user }}
    - group: {{ salt_group }}

{% endfor %}


# Ownership and permissions on Salt directories
{% for salt_dir in ('salt', 'pillars', 'formulas') %}

.Ownership and permissions on /srv/{{ salt_dir }}:
  file.directory:
    - name: /srv/{{ salt_dir }}
    - user: {{ salt_user }}
    - group: {{ salt_group }}
    - file_mode: {{ file_mode }}
    - dir_mode: {{ dir_mode }}
    - recurse:
      - user
      - group
      - mode

{% endfor %}


# Create a keypair for Salt Cloud to use
.Salt Cloud keys directory exists:
  file.directory:
    - name: /etc/salt/cloud.keys

.Salt Cloud master key exists:
  cmd.run:
    - name: ssh-keygen -f /etc/salt/cloud.keys/saltlick-{{ grains['id'] }}_rsa {# -#}
                       -C saltlick@{{ grains['id'] }} -t rsa -N ''
    - onlyif: test ! -f /etc/salt/cloud.keys/saltlick-{{ grains['id'] }}_rsa


# Salt configuration directory permissions
