#!/usr/bin/env python

from salt.cloud import CloudClient
from os import environ
import sys


SALT_CLOUD_CONFIG = environ.get('SALT_CLOUD_CONFIG', '/etc/salt/cloud/')


def main():
    print(sys.path)

    cloud_client = CloudClient(SALT_CLOUD_CONFIG)



if __name__ == '__main__':
    main()
