#!/bin/sh -

# We just download the bootstrap script by default and execute that.
if [ -x /usr/bin/curl ]; then
    /usr/bin/curl -L http://bootstrap.saltstack.org | sudo sh -s -- "$@"
elif [ -x /usr/bin/fetch ]; then
    /usr/bin/fetch -o - http://bootstrap.saltstack.org | sudo sh -s -- "$@"
else
    python \
        -c 'import urllib; print urllib.urlopen("http://bootstrap.saltstack.org").read()' \
        | sudo sh -s -- "$@"
fi
