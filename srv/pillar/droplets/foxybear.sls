{% from 'projects/hipikat_org.sls' import hipikat_org %}

{% set hipikat_watch_dirs = ['etc', 'lib', 'src', 'var/env'] %}

{% set hipikat_dev = { 
    'name': 'hipi_dev',
    'settings': 'Development',
    'fqdn': grains['host'],
    'watch': true,
    'enabled': true,
    'http_basic_auth': true,
} %}

django_projects:
  {{ hipikat_org(**hipikat_dev)|indent(2) }}

nginx_default:
  directives:
    - return 444
