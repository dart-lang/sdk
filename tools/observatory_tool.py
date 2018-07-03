#!/usr/bin/env python
# Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
"""Helper for building and deploying Observatory"""

import os
import shutil
import sys

IGNORE_PATTERNS = shutil.ignore_patterns(
    '$sdk',
    '*.concat.js',
    '*.dart',
    '*.log',
    '*.map',
    '*.precompiled.js',
    '*.scriptUrls',
    '*_buildLogs*',
    '*~',
    'CustomElements.*',
    'HTMLImports.*',
    'MutationObserver.*',
    'ShadowDOM.*',
    'bower.json',
    'dart_support.*',
    'interop_support.*',
    'package.json',
    'unittest*',
    'webcomponents-lite.js',
    'webcomponents.*')

# - Copy over the filtered web directory
# - Merge in the .js file
# - Copy over the filtered dependency lib directories
# - Copy over the filtered observatory package
def Deploy(output_dir, web_dir, observatory_lib, js_file, pub_packages_dir):
  shutil.rmtree(output_dir)
  os.makedirs(output_dir)

  output_web_dir = os.path.join(output_dir, 'web')
  shutil.copytree(web_dir, output_web_dir, ignore=IGNORE_PATTERNS)
  os.utime(os.path.join(output_web_dir, 'index.html'), None)

  shutil.copy(js_file, output_web_dir)

  packages_dir = os.path.join(output_web_dir, 'packages')
  os.makedirs(packages_dir)
  for subdir in os.listdir(pub_packages_dir):
    libdir = os.path.join(pub_packages_dir, subdir, 'lib')
    if os.path.isdir(libdir):
      shutil.copytree(libdir, os.path.join(packages_dir, subdir),
                      ignore=IGNORE_PATTERNS)
  shutil.copytree(observatory_lib, os.path.join(packages_dir, 'observatory'),
                  ignore=IGNORE_PATTERNS)


def Main():
  args = sys.argv[1:]
  return Deploy(args[0], args[1], args[2], args[3], args[4])


if __name__ == '__main__':
  sys.exit(Main());
