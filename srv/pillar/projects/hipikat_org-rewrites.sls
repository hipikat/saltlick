
{% macro hipikat_rewrites() %}
- rewrite "^/fa/?$"   http://www.furaffinity.net/user/hipikat/         permanent
- rewrite "^/g\+/?$"  https://plus.google.com/u/0/+AdamWright-Hipikat  permanent
{% endmacro %}
