#!/bin/bash -
#
# Install Salt for development
# Tested on Ubuntu 15.04
#
# Copyright 2015 Adam Wright <adam@hipikat.org>
# Licensed under the BSD 2-Clause license, as part of Saltlick
#
# https://github.com/hipikat/saltlick/blob/master/scripts/install-salt


# This script must be run as root...
if [ "$(id -u)" -ne "0" ]; then
    echo "This script must be run as root."
    exit 1
fi

# Display usage instructions for this script
function usage() {
    cat << EOT

  Usage:
  $ install_salt_dev.sh [options...]
    or...
  $ curl -L http://hpk.io/install_salt_dev.sh | bash -s -- [options...]
    or...
  $ wget -q -O- http://hpk.io/install_salt_dev.sh | bash -s -- [options...]
    etc.

  -h                Display this help message.
  -b [tag|branch]   Git tag or branch, for the Salt repository.
  -D                Show debug output.
  -g [origin]       Salt repository URL. Default:
                        git://github.com/saltstack/salt.git
  -k [dir]          Temporary directory holding the minion keys which
                        will pre-seed the master.
  -A [master]       Domain name or IP address of the Salt master,
                        default: 'salt'.
  -M                Also enable the Salt master.
  -N                Do not enable the Salt minion.

EOT
}   # --- End of function usage ----


# Set defaults
_SALT_GIT_URL='git@github.com:saltstack/salt.git'
_SALT_MASTER_ADDRESS='salt'
_ENABLE_MASTER=
_ENABLE_MINION=1

# Parse command-line options
while getopts ":hb:Dg:k:A:MN" opt; do
    case "${opt}" in
        h ) usage; exit 0                       ;;
        b ) _GIT_CHECKOUT=$OPTARG               ;;
        D ) _ECHO_DEBUG=1                       ;;  # TODO
        g ) _SALT_GIT_URL=$OPTARG               ;;
        k ) _TEMP_KEYS_DIR=$OPTARG                  # TODO
            if [ ! -d "$_TEMP_KEYS_DIR" ]; then
                echo "The pre-seed keys directory ${_TEMP_KEYS_DIR} does not exist!"
                exit 1
            fi
            ;;
        A ) _SALT_MASTER_ADDRESS=$OPTARG        ;;  # TODO
        M ) _ENABLE_MASTER=1                    ;;  # TODO
        N ) _ENABLE_MINION=                     ;;  # TODO
        \?) echo
            echo "Option does not exist: $OPTARG" >&2
            usage
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))


# If the first argument isn't an executable on the user's path,
# evaluate the rest of the arguments.
function if_not_installed() {
    if ! type -p "$1" &>/dev/null; then
        echo -e "\n--- Command '$1' not found, running: ${@:2}"
        eval "${@:2}"
    fi
}

# Echo the arguments with a '--- ' prefix, then evaluate them
function echo_and_eval() {
    echo -e "\n--- $@"
    eval "$@"
}


# Ensure easy_install, git
if_not_installed easy_install apt-get install python-setuptools
if_not_installed git apt-get install git

# Ensure pip
if_not_installed pip easy_install pip

# Ensure virtualenv
if_not_installed virtualenv pip install virtualenv

# Create Salt virtualenv
if [ ! -d /usr/local/salt ]; then
    echo_and_eval virtualenv /usr/local/salt
fi
pushd /usr/local/salt >/dev/null        # pushd into 'salt' virtualenv (1)

# Activate salt virtualenv
if [ -n "$VIRTUAL_ENV" ]; then
    old_virtual_env=$VIRTUAL_ENV
fi
source bin/activate

# Git clone Salt
if [ ! -d /usr/local/salt/salt ]; then
    echo_and_eval git clone $_SALT_GIT_URL /usr/local/salt/salt
fi

pushd salt >/dev/null                   # pushd into Salt repository (2)
echo_and_eval git fetch --tags origin

# Switch to a Salt branch, if one was specified
# NB: The regex is designed to match '* branch_foo' or '* (detached from branch_foo)'
if [ -n "$GIT_CHECKOUT" ] && ! $(git branch | grep "*.* $GIT_CHECKOUT\()\|$\)"); then
    echo_and_eval git checkout $GIT_CHECKOUT
fi

# Install Salt requirements in virtualenv
if [ -f dev_requirements_python27.txt ]; then
    # Older (at least 2015.2)
    echo_and_eval pip install -r dev_requirements_python27.txt

elif [ -d requirements ]; then
    # Newer (some time before 2015.8)
    pushd requirements >/dev/null       # pushd into Salt requirements directory (3)
    if [ -f dev_python27.txt ]; then
        echo_and_eval pip install -r dev_python27.txt
    fi
    if [ -f zeromq.txt ]; then
        echo_and_eval pip install -r zeromq.txt
    fi
    popd >/dev/null                     # popd into Salt repository (2)
fi

# Install Salt (as editable)
pip install -e .

# Symlink salt binaries into /usr/local/bin
popd >/dev/null                         # popd into 'salt' virtualenv (1)
pushd /usr/local/bin >/dev/null         # pushd into local bin directory (2)
salt_bins=$(ls /usr/local/salt/bin/salt*)
for bin_path in $salt_bins; do
    echo_and_eval ln -fs $bin_path ./${bin_path##*/}
done
popd >/dev/null                         # popd into 'salt' virtualenv (1)
popd >/dev/null                         # popd into original working directory (0)
deactivate

# Install Supervisor
if ! type -p supervisorctl &>/dev/null; then
    echo_and_eval apt-get install supervisor
fi

# Clean-up
if [ -n "$old_virtual_env" ]; then
    pushd $old_virtual_env >/dev/null
    source bin/activate
    popd >/dev/null
fi
echo "Script completed successfullly!"
exit 0
