### System administrators. Just me so far.
##########################################

{% from 'users-secrets.sls' import hipikat_htpasswd %}

users:
  hipikat:
    fullname: Adam Wright
    sudouser: True
    shell: /bin/bash
    groups:
      - root
      - www-data
    dotfiles:
      repository: https://github.com/hipikat/dotfiles.git
      install_cmd: 'bash bin/install.sh --force'
    ssh_auth:
      # For some reason this public key, as a single line,
      # makes vim hang when syntax highlighting is enabled.
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDKyCuPu+CjJ8z/Xiy8p57JxtbHwCvZe/KPKjkoLauObR9S{# -#}
H1WLwbkgT8nOtYQskuIwcoHERp7GkSjCcI1qGYyILRYPIKmwC2mXyCFtb47PejAS8AhnT9XJ7luPuOL0En7X3las3LfZ{# -#}
XjwwBjU1Hr9ZDZMImcki4rUpPcjKhgvsHI/eALO0FcV/4BCYrBKTTl1S8V1nolMb+D4VCpr/a43akqARtr04QKZCQZq/{# -#}
7/q8Dts8f4TaR/YxXEK2n4TZsWdnsxkmGyQwdS0i9qUlyxdXSGLYW9vn+aceOgaYA5RiU/CO2wVm7SCungHjCBgPOQhr{# -#}
bBj6RYWBv3Od1yYsRHad zeno@trepp
    htpasswd: {{ hipikat_htpasswd() }}
