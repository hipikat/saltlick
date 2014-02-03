### System-wide packages to be installed
##########################################

# Standard Debian/Ubuntu packages
global_pkgs:
  pkg.installed:
    - pkgs:
      - exuberant-ctags   # Parsing code in Vim
      - git               # Version control
      - mosh              # Persistent ssh sessions
      - screen            # Terminal window management
