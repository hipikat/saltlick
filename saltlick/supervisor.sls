#!stateconf -o yaml . jinja
#
# Install Supervisor
###########################################


# NB: I'm seeing what this person's seeing:
# http://masato.github.io/2014/11/16/salt-pip-installed-unavailable/
#
#.Do not use system-package-managed pip, it breaks the pip.installed state:
#  pkg.purged:
#    - name: python-pip
#
#.Install System-pip:
#  cmd:
#    - run
#    - name: easy_install --script-dir=/usr/bin -U pip
#    - reload_modules: true
#    - unless: test -f /usr/bin/pip
#
.System packages required to install Supervisor:
  pkg.installed:
    - pkgs:
      - python-pip

.System-Python-Pip install of Supervisor:
  pip.installed:
    - name: supervisor

.Supervisor configuration directory:
  file.directory:
    - name: /etc/supervisor
    - makedirs: True


#.Default Supervisor configuration file:
#  cmd.run:
#    - name: echo_supervisord_conf > /etc/supervisord.conf
#    - unless: -f /etc/supervisord.conf

#.Supervisor requires explicitly stating user when running as root:
#  file.replace:
#    - name: /etc/supervisord.conf
#    - pattern: "^;?user=[^ ]* *; \\(default is current user, required if root\\)$"
#    - repl: "user=root                    ; (default is current user, required if root)"
#    - backup: False

# !!! MULTILINE doesn't work thanks to issue #7999
#.Control edits on Supervisor unix_http_server block if we're the installer:
#  file.replace:
#    - name: /etc/supervisord.conf
#    - pattern: |
#        \[unix_http_server\].*\n.*\n.*
#    - repl: "\n\nomfg\n\n"
#    - bufsize: file
#    - flags: ['DOTALL', 'MULTILINE']

#.Control edits on Supervisor unix_http_server block if we're the installer:
#  file.blockreplace:
#    - name: /etc/supervisord.conf
#    - marker_start: '[unix_http_server]'
#    - marker_end: '[inet_http_server]'
#    - content: "\
#file=/var/run/supervisor.sock ; (the path to the socket file)\n\
#chmod=0700                    ; socket file mode (default 0700)\n\
#chown=root:root               ; socket file uid:gid owner\n\
#username=root                 ; (default is no username (open server))\n\
#password=12345                ; (default is no password (open server))\n\n"
#    - backup: False
#    - watch:
#      - cmd: .Default Supervisor configuration file


#.Supervisor PID-file configuration:
#  file.replace:
#    - name: /etc/supervisord.conf
#    - pattern: "^;?pidfile=[^ ]* *; \\(supervisord pidfile;"
#    - repl: "pidfile=/var/run/supervisord.pid    ; (supervisord pidfile;"
#    - backup: False
#    - count: 1


#.Supervisor requires an authentication username when running as root:
#  file.replace:
#    - name: /etc/supervisord.conf
#    - pattern: "^;?username=user"
#    - repl: "username=root"
#    - count: 1
#
#.Supervisor requires an authentication password when running as root:
#  file.replace:
#    - name: /etc/supervisord.conf
#    - pattern: "^;?password=123  "
#    - repl: "password=12345"
#    - count: 1

#.Supervisor log directory:
#  file.directory:
#    - name: /var/log/supervisor
#    - makedirs: True
#    - mode: 750

#.Supervisor log file configuration:
#  file.replace:
#    - name: /etc/supervisord.conf
#    - pattern: "^;?logfile=[^ ]* *; \\(main log file;"
#    - repl: "logfile=/var/log/supervisor.log     ; (main log file;"
#    - backup: False
#    - count: 1

.Managed Supervisor configuration files:
  file.recurse:
    - name: /etc/supervisor
    - source: salt://saltlick/templates/supervisor 

.Link /etc/supervisord.conf to /etc/supervisor/main.ini for supervisorctl:
  file.symlink:
    - name: /etc/supervisord.conf
    - target: /etc/supervisor/main.ini

.Program configuration 'enabled' directory for Supervisor:
  file.directory:
    - name: /etc/supervisor/programs-enabled

.Supervisor main init script:
  file.managed:
    - name: /etc/init.d/supervisord
    - source: salt://saltlick/templates/init-supervisord
    - mode: 755

.Update System V-style init script links to the Supervisor init script:
  cmd.wait:
    - name: update-rc.d supervisord defaults
    - watch:
      - file: .Supervisor main init script
