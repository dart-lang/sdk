#!/usr/bin/env python
# Copyright 2016 The Dart project authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

# This script downloads the latest dev SDK from
# http://gsdview.appspot.com/dart-archive/channels/dev/raw/latest/sdk/
# into tools/sdks/$HOST_OS/. It is intended to be invoked from Jiri hooks in
# a Fuchsia checkout.

import os
import sys
import zipfile
import urllib
import utils

HOST_OS = utils.GuessOS()
HOST_ARCH = utils.GuessArchitecture()
SCRIPT_DIR = os.path.dirname(sys.argv[0])
DART_ROOT = os.path.realpath(os.path.join(SCRIPT_DIR, '..'))
FUCHSIA_ROOT = os.path.realpath(os.path.join(DART_ROOT, '..', '..'))
FLUTTER_ROOT = os.path.join(FUCHSIA_ROOT, 'lib', 'flutter')

DEFAULT_DART_VERSION = 'latest'
BASE_URL = 'http://gsdview.appspot.com/dart-archive/channels/dev/raw/%s/sdk/%s'

def host_os_for_sdk(host_os):
  if host_os.startswith('macos'):
    return 'mac'
  if host_os.startswith('win'):
    return 'windows'
  return host_os

# Python's zipfile doesn't preserve file permissions during extraction, so we
# have to do it manually.
def extract_file(zf, info, extract_dir):
  try:
    zf.extract(info.filename, path=extract_dir)
    out_path = os.path.join(extract_dir, info.filename)
    perm = info.external_attr >> 16L
    os.chmod(out_path, perm)
  except IOError as err:
    if 'dart-sdk/bin/dart' in err.filename:
      print('Failed to extract the new Dart SDK dart binary. ' +
            'Kill stale instances (like the analyzer) and try the update again')
      return False
    raise
  return True

def main(argv):
  host_os = host_os_for_sdk(HOST_OS)
  zip_file = ('dartsdk-%s-x64-release.zip' % HOST_OS)
  sha_file = zip_file + '.sha256sum'
  sdk_path = os.path.join(DART_ROOT, 'tools', 'sdks', host_os)
  local_sha_path = os.path.join(sdk_path, sha_file)
  remote_sha_path = os.path.join(sdk_path, sha_file + '.remote')
  zip_path = os.path.join(sdk_path, zip_file)

  # If we're in a Fuchsia checkout with Flutter nearby, pull the same dev SDK
  # version that Flutter says it wants. Otherwise, pull the latest dev SDK.
  sdk_version_path = os.path.join(
      FLUTTER_ROOT, 'bin', 'internal', 'dart-sdk.version')
  sdk_version = DEFAULT_DART_VERSION
  if os.path.isfile(sdk_version_path):
    with open(sdk_version_path, 'r') as fp:
      sdk_version = fp.read().strip()

  sha_url = (BASE_URL % (sdk_version, sha_file))
  zip_url = (BASE_URL % (sdk_version, zip_file))

  local_sha = ''
  if os.path.isfile(local_sha_path):
    with open(local_sha_path, 'r') as fp:
      local_sha = fp.read()

  remote_sha = ''
  urllib.urlretrieve(sha_url, remote_sha_path)
  with open(remote_sha_path, 'r') as fp:
    remote_sha = fp.read()
  os.remove(remote_sha_path)

  if local_sha == '' or local_sha != remote_sha:
    print 'Downloading prebuilt Dart SDK from: ' + zip_url
    urllib.urlretrieve(zip_url, zip_path)
    with zipfile.ZipFile(zip_path, 'r') as zf:
      for info in zf.infolist():
        if not extract_file(zf, info, sdk_path):
          return -1
    with open(local_sha_path, 'w') as fp:
      fp.write(remote_sha)
  return 0

if __name__ == '__main__':
  sys.exit(main(sys.argv))
