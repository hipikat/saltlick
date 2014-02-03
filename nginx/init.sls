# Nginx setup
#############

nginx:
  pkg:
    - installed

/etc/nginx/nginx.conf:
  file.managed:
    - template: jinja
    - user: root
    - group: root
    - mode: 444
    - source: salt://nginx/templates/nginx.conf
    - require:
      - pkg: nginx

# A default Nginx server response, for when hostnames don't match any
# configured servers - especially useful for development boxes with
# multiple projects being served, where Nginx will otherwise make the
# first (usually non-deterministically) loaded server the default.
{% if 'nginx_default' not in pillar %}
/etc/nginx/sites-enabled/default:
  file:
    - absent
{% else %}
/etc/nginx/sites-available/default:
  file.managed:
    - source: salt://nginx/templates/default.conf
    - mode: 444 
    - template: jinja
    - context:
        directives: {{ pillar['nginx_default']['directives'] }}

/etc/nginx/sites-enabled/default:
  file.symlink:
    - target: /etc/nginx/sites-available/default
{% endif %}
