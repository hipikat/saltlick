### Top-level pillar - map configuration objects to minions
##########################################

base:
  '*':            # Every minion gets...
    - users       # System administrators
    - miner

  #'uwa-visualid':
  #  - machines.uwa-visualid
  
  'hipi-dev1':
    - machines.hipi-dev1

