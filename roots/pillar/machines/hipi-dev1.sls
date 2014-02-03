{% from 'projects/hipikat_org.sls' import hipikat_org %}


{% set hipikat_dev = { 
    'name': 'hipi_dev',
    'settings': 'Development',
    'fqdn': 'hipikat.org',
    'port': 8871,
    'watch': true,
    'enabled': true,
    'http_basic_auth': false,
} %}

django_projects:
  {{ hipikat_org(**hipikat_dev)|indent(2) }}

nginx_default:
  directives:
    - return 444
