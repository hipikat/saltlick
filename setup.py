#!/usr/bin/env python
"""
Pythonic setup for Saltlick.
http://github.com/hipikat/saltlick
"""

import setuptools


setuptools.setup(
    version='0.0.1',
    name='saltlick',
    description='Salt tools',
    author='Adam Wright',
    author_email='adam@hipikat.org',
    license='BSD 2-Clause; see LICENSE.rst',
    url='https://github.com/hipikat/saltlick',
    scripts=['scripts/saltlick'],
    entry_points = {
        'console_scripts': [
            'saltlick=saltlick:main',
        ],
    }
)
