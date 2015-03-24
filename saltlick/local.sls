#!stateconf -o yaml . jinja
#
# Install Salt roots, pillars, formulas, etc.
###########################################


{% set saltlick = pillar.get('saltlick', {}) %}


# Install Salt roots and pillars
{% for part in ('roots', 'pillars') %}
  {% set salt_part = saltlick.get('salt_' ~ part) %}
  {% if salt_part %}
    {% if salt_part is not mapping %}
      {% set salt_part = {'url': salt_part } %}
    {% endif %}

.Salt {{ part }} git checkout:
  git.latest:
    - name: {{ salt_part['url'] }}
    {% if 'rev' in salt_part %}
    - rev: {{ salt_part['rev'] }}
    {% endif %}
    {% if part == 'roots' %}
    - target: /srv/salt
    {% elif part == 'pillars' %}
    - target: /srv/pillar
    {% endif %}
    - force: {{ salt_part.get('force', 'False') }}
    {% if 'deploy_key' in salt_part %}
    - identity: /etc/saltlick/deploy_keys/{{ salt_part['deploy_key'] }}
    {% endif %}

  {% endif %}
{% endfor %}


# Install Salt formulas
{% set formulas = saltlick.get('salt_formulas', {}) %}
{% for formula_name, formula_spec in formulas.items() %}
  {% if formula_spec is not mapping %}
    {% set formula_spec = {'url': formula_spec} %}
  {% endif %}

.Git-checkout formula '{{ formula_name }}':
  git.latest:
    - name: {{ formula_spec['url'] }}
    {% if 'rev' in formula_spec %}
    - rev: {{ formula_spec['rev'] }}
    {% endif %}
    - target: /srv/formulas/{{ formula_name }}-formula
    - force: {{ formula_spec.get('force', 'False') }}
    {% if 'deploy_key' in formula_spec %}
    - identity: /etc/saltlick/deploy_keys/{{ formula_spec['deploy_key'] }}
    {% endif %}
    {% if 'remote_name' in formula_spec %}
    - remote_name: {{ formula_spec['remote_name'] }}
    {% endif %}

.Symlink formula '{{ formula_name }}' into Salt roots:
  file.symlink:
    - name: /srv/salt/{{ formula_name }}
    - target: /srv/formulas/{{ formula_name }}-formula/{{ formula_name }}

{% endfor %}
