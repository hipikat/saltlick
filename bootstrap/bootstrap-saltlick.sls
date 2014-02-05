# TODO: Make this configurable from Jinja dicts.

https://github.com/hipikat/salt-roots.git:
  git.latest:
    - rev: master
    - target: /srv/salt
    - force: true

https://github.com/hipikat/salt-formulas.git:
  git.latest:
    - rev: master
    - target: /srv/formulas

{% for formula in ('users',) %}
/srv/salt/{{ formula }}: 
  file.symlink:
    - target: /srv/formulas/{{ formula }}-formula/{{ formula }}
    - require:
      - git: https://github.com/hipikat/salt-roots.git
{% endfor %}

https://github.com/hipikat/salt-pillars.git:
  git.latest:
    - rev: master
    - target: /srv/pillar

/srv/pillar/users-secrets.sls:
  file.copy:
    - source: /srv/vagrant/secrets/users-secrets.sls
    - require:
      - git: https://github.com/hipikat/salt-pillars.git

{% for salt_dir in ('/srv/salt', '/srv/pillar', '/srv/formulas' '/var/log/salt') %}
{{ salt_dir }}:
  file.directory:
    - dir_mode: 775
    - file_mode: 664
    - recurse:
      - mode
{% endfor %}
