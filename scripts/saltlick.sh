#!/bin/bash
#
# Usage: saltlick [vm_profile] [vm_name]
#
# Create a new VM with Salt-Cloud, suppressing the default Salt
# installation. Then install Salt for development with saltlick-bootstrap.

if [ "$#" -ne "2" ]; then
    echo "Usage: saltlick [vm_profile] [vm_name]"
    exit 1
fi


function slk_bootstrap() {

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
    salt-ssh --refresh "$1" state.sls saltlick.salt_install.dev

    # Generate new minion key
    echo "Generating minion keys in /tmp/saltlick-bootstrap ..."
    salt-key --gen-keys-dir=/tmp/saltlick-bootstrap --gen-keys="$1"

    # Pre-accept the minion on this master
    cp "$1".pub /etc/salt/pki/master/minions_autosign/"$1"

    # Send the minion its new keys, point it at this master, turn it on.
    escaped_minion_pub=`cat "$1".pub | awk '{printf "%s\\\\n",$0} END {print ""}'`
    escaped_minion_pem=`cat "$1".pem | awk '{printf "%s\\\\n",$0} END {print ""}'`

    echo "Creating minion keys in $1:/etc/salt/pki/minion"
    salt-ssh --raw "$1" "mkdir -p /etc/salt/pki/minion;
        echo -e '$escaped_minion_pub' > /etc/salt/pki/minion/minion.pub;
        umask 177;
        echo -e '$escaped_minion_pem' > /etc/salt/pki/minion/minion.pem;
        sed -i 's/#\?master:.*/master: $2/' /etc/salt/minion;
        service supervisord start
        supervisorctl start salt-minion"

    # Turn it on!
    # TODO: Account for other forms of startup than Supervisor...


    ### Cleanup
    # TODO: Destroy the local minion keys!
    cd "$OLD_PWD"
}


vm_profile="$1"
vm_name="$2"

new_vm=`salt-cloud --output=json -p "$vm_profile" "$vm_name"`
if [ "$?" -ne "0" ]; then
    echo "Failed to deploy VM $vm_name."
    exit $?
fi

new_vm_ip=`echo "$new_vm" | jq -r ".$vm_name.ip_address"`

echo --
echo "$new_vm_ip"
echo --

# TODO: Create temporary roster file to pass to slk_bootstrap

# Use $SLK_PRIVATE_MASTER_IP if set in the environment?
# or $SLK_MASTER_IP if not, or `hostname`?
#slk_bootstrap "$vm_name" kerry-a.hpk.io   # ... [get fqdn by defulat or take option?]

# now salt-key -a

# now... send secrets?? no no just if special master type. special case.

# 
