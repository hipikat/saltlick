#!stateconf -o yaml . jinja
#
# Install Salt-Cloud configuration files from pillars
###########################################


{% set saltlick = pillar.get('saltlick', {}) %}


{% if saltlick.get('salt_cloud', {}).get('providers') %}
.Salt-Cloud providers from pillar:
  file.managed:
    - name: /etc/salt/cloud.providers.d/saltlick.conf
    - makedirs: True
    - contents: |
        # Produced by the saltlick.salt_cloud formula, rendering
        # data from pillar['saltlick']['salt_cloud']['providers']
        
        {{ saltlick['salt_cloud']['providers']|yaml(False)|indent(8) }}

.Restrict read permissions on Salt-Cloud providers directory:
  file.directory:
    - name: /etc/salt/cloud.providers.d
    - dir_mode: 500
    - file_mode: 400
    - recurse:
      - mode

{% endif %}


{% if saltlick.get('salt_cloud', {}).get('profiles') %}
.Salt-Cloud profiles from pillar:
  file.managed:
    - name: /etc/salt/cloud.profiles.d/saltlick.conf
    - makedirs: True
    - contents: |
        # Produced by the saltlick.salt_cloud formula, rendering
        # data from pillar['saltlick']['salt_cloud']['profiles']
        
        {{ saltlick['salt_cloud']['profiles']|yaml(False)|indent(8) }}
{% endif %}
