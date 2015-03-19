#!stateconf -o yaml . jinja
#
# Saltlick installs and configures Salt masters
###########################################

{% set saltlick = pillar.get('saltlick', {}) %}


# Installing Salt needs to come first, if required
{% if saltlick.get('salt_install', {}).get('type') %}
  {% set salt_install_type = saltlick['salt_install']['type'] %}
{% endif %}


# Include includes
include:
  - saltlick.null
  {% if salt_install_type is defined %}
  - saltlick.salt_install.{{ salt_install_type }}
  {% endif %}


