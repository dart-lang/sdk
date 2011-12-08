#!/bin/bash

# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Run to install the necessary components to run webdriver on the buildbots.
# NOTE: YOU WILL NEED TO RUN THIS SCRIPT AS ROOT IN ORDER FOR IT TO SUCCESSFULLY
# INSTALL COMPONENTS.

curl http://python-distribute.org/distribute_setup.py | sudo python
curl https://raw.github.com/pypa/pip/master/contrib/get-pip.py | sudo python
pip install -U selenium
wget -O - http://releases.mozilla.org/pub/mozilla.org/firefox/releases/8.0.1/linux-x86_64/en-US/firefox-8.0.1.tar.bz2 | tar -C ~ -jxv
