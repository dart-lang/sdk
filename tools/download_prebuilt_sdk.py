#!/usr/bin/env python
# Copyright 2016 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

import os
import subprocess
import sys
import tarfile
import urllib
import utils

HOST_OS = utils.GuessOS()
HOST_ARCH = utils.GuessArchitecture()
SCRIPT_DIR = os.path.dirname(sys.argv[0])
DART_ROOT = os.path.realpath(os.path.join(SCRIPT_DIR, '..'))

BUCKET_NAME = 'dart-dependencies'

def host_os_for_sdk(host_os):
  if host_os.startswith('macos'):
    return 'mac'
  if host_os.startswith('win'):
    return 'win'
  return host_os

def main(argv):
  host_os = host_os_for_sdk(HOST_OS)
  sdk_path = os.path.join(DART_ROOT, 'tools', 'sdks', host_os)
  stamp_path = os.path.join(sdk_path, 'dart-sdk.tar.gz.stamp')
  sha_path = os.path.join(sdk_path, 'dart-sdk.tar.gz.sha1')
  tgz_path = os.path.join(sdk_path, 'dart-sdk.tar.gz')

  stamp = ''
  if os.path.isfile(stamp_path):
    with open(stamp_path, 'r') as fp:
      stamp = fp.read()

  with open(sha_path, 'r') as fp:
    sha = fp.read()

  if stamp != sha:
    url = ('https://%s.storage.googleapis.com/%s' % (BUCKET_NAME, sha))
    print 'Downloading prebuilt Dart SDK from: ' + url
    urllib.urlretrieve(url, tgz_path)
    with tarfile.open(tgz_path) as tar:
      tar.extractall(sdk_path)
    with open(stamp_path, 'w') as fp:
      fp.write(sha)

if __name__ == '__main__':
  sys.exit(main(sys.argv))
