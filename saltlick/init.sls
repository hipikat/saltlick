#!stateconf -o yaml . jinja
#
# Saltlick installs and configures Salt masters
###########################################

{% set saltlick = pillar.get('saltlick', {}) %}


# Include includes
include:
  - saltlick.null

  # Install Supervisor (if required)
  {% if pillar.get('controllers', {}).get('supervisor') == 'saltlick.supervisor' %}
  - saltlick.supervisor
  {% endif %}

  # Install Salt
  {% if saltlick.get('salt_install', {}).get('type') %}
  - saltlick.salt_install.{{ saltlick['salt_install']['type'] }}
  {% endif %}

  # Install secrets
  {% if saltlick.get('secrets', {}) %}
  - saltlick.secrets
  {% endif %}

  # Install Salt roots, pillars, formulas, etc.
  - saltlick.local
