#!stateconf -o yaml . jinja
#
# Install deploy keys
###########################################


{% set saltlick = pillar.get('saltlick', {}) %}


# Install deployment keys in /etc/saltlick/deploy_keys
{% for key_name, key_parts in saltlick.get('deploy_keys', {}).items() %}

  {% if 'private' in key_parts %}
.Private deploy key '{{ key_name }}':
  file.managed:
    - name: /etc/saltlick/deploy_keys/{{ key_name }}
    - contents_pillar: saltlick:deploy_keys:{{ key_name }}:private
    - mode: 400 
    - makedirs: True
  {% endif %}

  {% if 'public' in key_parts %}
.Public deploy key '{{ key_name }}':
  file.managed:
    - name: /etc/saltlick/deploy_keys/{{ key_name }}.pub
    - contents_pillar: saltlick:deploy_keys:{{ key_name }}:public
    - mode: 444 
    - makedirs: True
  {% endif %}

{% endfor %}
