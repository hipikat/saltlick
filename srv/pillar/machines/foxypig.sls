{% from 'projects/hipikat_org.sls' import hipikat_org, foobar %}

{% set hipikat_prod = { 
    'name': 'hipi_prod',
    'settings': 'Production',
} %}

{% set hipikat_dev = { 
    'name': 'hipi_dev',
    'settings': 'Development',
    'port': 8870,
    'run_uwsgi': false,
} %}

django_projects:
  {{ hipikat_org(**hipikat_prod)|indent(2) }}
  {{ hipikat_org(**hipikat_dev)|indent(2) }}
