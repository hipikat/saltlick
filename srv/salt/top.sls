### Top-level SaLt State - map state moduels to minions
### http://docs.saltstack.com/ref/states/top.html
##########################################

base:
  '*':
    - packages
    - python
    - users
    - projects
