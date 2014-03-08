# TODO: Make this configurable from Jinja dicts.

{% set salt_roots = 'https://github.com/hipikat/salt-roots.git' %}
{% set salt_pillars = 'https://github.com/hipikat/salt-pillars.git' %}
{% set formulas = {
  'users': ('https://github.com/hipikat/users-formula.git', 'dotfiles'),
  'chippery': ('https://github.com/hipikat/chippery.git', 'master'),
} %}

# Install salt roots
https://github.com/hipikat/salt-roots.git:
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
{{ salt_pillars }}:
  git.latest:
    - rev: master
    - target: /srv/pillar

# Copy secrets from Vagrant mount
/srv/pillar/secrets.sls:
  file.copy:
    - source: /mnt/saltlick/secrets.sls

# Fix permissions (TODO: Check dirs exist)
{% for salt_dir in (
  '/srv/salt',
  '/srv/pillar',
  '/srv/formulas',
) %}
{{ salt_dir }}-perms:
  file.directory:
    - name: {{ salt_dir }}
    - dir_mode: 775
    - file_mode: 664
    - recurse:
      - mode
{% endfor %}
