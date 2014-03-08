#
# Saltlick installs and configures Salt masters
###########################################

{% set saltlick = pillar.get('saltlick') %}
{% set salt_roots = 'https://github.com/hipikat/salt-roots.git' %}
{% set pillars = 'https://github.com/hipikat/salt-pillars.git' %}
{% set formulas = {
  'saltlick': ('https://github.com/hipikat/saltlick-formula.git', 'master'),
  'users': ('https://github.com/hipikat/users-formula.git', 'dotfiles'),
  'chippery': ('https://github.com/hipikat/chippery.git', 'master'),
} %}


# Packages required on Salt masters
saltlick-sys-packages:
  pkg.installed:
    - pkgs:
      - python-pip

saltlick-py-packages:
  pip.installed:
    - name: apache-libcloud

# Install salt roots
{{ salt_roots }}:
  git.latest:
    - rev: master
    - target: /srv/salt
    - force: true

# Install formulas
{% if formulas is defined %}
/srv/formulas:
  file.directory:
    - makedirs: True

{% for formula_name, formula_repo in formulas.items() %}
{{ formula_repo[0] }}:
  git.latest:
    - rev: master
    - target: /srv/formulas/{{ formula_name }}-formula
    - rev: {{ formula_repo[1] }}

/srv/salt/{{ formula_name }}: 
  file.symlink:
    - target: /srv/formulas/{{ formula_name }}-formula/{{ formula_name }}
{% endfor %}
{% endif %}

# Install pillars
{{ pillars }}:
  git.latest:
    - rev: master
    - target: /srv/pillar

# Install pillar secrets from Saltlick
/srv/pillar/secrets.sls:
  file.copy:
    - source: /srv/formulas/saltlick-formula/secrets.sls

# Fix permissions (TODO: Check dirs exist)
{% for salt_dir in (
  '/srv/salt',
  '/srv/pillar',
  '/srv/formulas',
) %}
perms={{ salt_dir }}:
  file.directory:
    - name: {{ salt_dir }}
    - dir_mode: 775
    - file_mode: 664
    - recurse:
      - mode
{% endfor %}


# This is a pre-bootstrapped master; configure based on pillar data.
{% if saltlick %}

# Configure Salt Cloud
# TODO: Support for multiple providers, profiles, etc.
{% if 'salt_cloud' in saltlick %}
{% set cloud = saltlick['salt_cloud'] %}

/etc/salt/cloud:
  file.managed:
    - source: salt://saltlick/templates/cloud
    - template: jinja
    - context:
        master_address: {{ cloud['master_address'] }}

/etc/salt/cloud.profiles:
  file.managed:
    - source: salt://saltlick/templates/cloud.profiles

/etc/salt/cloud.providers:
  file.managed:
    - source: salt://saltlick/templates/cloud.providers
    - template: jinja
    - context:
        client_key: {{ cloud['client_key'] }}
        api_key: {{ cloud['api_key'] }}

{% endif %}   # End if 'salt_cloud' in pillar['saltlick']

{% endif %}   # End if 'saltlick' in pillar
