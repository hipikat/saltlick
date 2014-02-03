https://github.com/hipikat/salt-formulas.git:
  git.latest:
    - rev: master
    - target: /srv/formulas

{% for formula in ('nginx', 'users') %}
/srv/salt/{{ formula }}:
  file.symlink:
    - target: /srv/formulas/{{ formula }}-formula/{{ formula }}
{% endfor %}

{% for salt_dir in ('/srv', '/var/log/salt') %}
{{ salt_dir }}:
  file.directory:
    - dir_mode: 775
    - file_mode: 664
    - recurse:
      - mode
{% endfor %}
