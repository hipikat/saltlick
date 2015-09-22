#!/bin/bash
#
# Bootstrap a fresh machine with Salt, configured for development and
# with a minion running, authorised and talking to this master.


### Sanity-check
# TODO: Check we're running as root or the salt user
if [ $# -lt 2 ]; then
    echo "Usage: $0 [target_in_roster] [master_address]"
    # TODO: [target_in_roster ...] (i.e. process multiple targets]
    exit 1
fi


### Pre-wash
OLD_PWD="$PWD"
# TODO: add a random identifier suffix to this directory
rm -Rf /tmp/saltlick-bootstrap


### Main
# Operate out of a root-read-only temporary directory
umask 077
cd /tmp
mkdir -p saltlick-bootstrap
cd saltlick-bootstrap

# Install Salt (running under Supervisor by default) to the machine
echo "Installing Salt on $1 ..."
salt-ssh -i --refresh "$1" state.sls saltlick.salt_install.dev

# Generate new minion key
echo "Generating minion keys in /tmp/saltlick-bootstrap ..."
salt-key --gen-keys-dir=/tmp/saltlick-bootstrap --gen-keys="$1"

# Pre-accept the minion on this master
cp "$1".pub /etc/salt/pki/master/minions_autosign/"$1"

# Send the minion its new keys, point it at this master, turn it on.
escaped_minion_pub=`cat "$1".pub | awk '{printf "%s\\\\n",$0} END {print ""}'`
escaped_minion_pem=`cat "$1".pem | awk '{printf "%s\\\\n",$0} END {print ""}'`

echo "Creating minion keys in $1:/etc/salt/pki/minion"
salt-ssh -i --raw "$1" "mkdir -p /etc/salt/pki/minion;
    echo -e '$escaped_minion_pub' > /etc/salt/pki/minion/minion.pub;
    umask 177;
    echo -e '$escaped_minion_pem' > /etc/salt/pki/minion/minion.pem;
    sed -i 's/#\?master:.*/master: $2/' /etc/salt/minion;
    service supervisord start"

# Turn it on!
# TODO: Account for other forms of startup than Supervisor...


### Cleanup
# TODO: Destroy the local minion keys!
cd "$OLD_PWD"
