#!/usr/local/evn python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# This is a first stab at creating a Firefox extension which can run Dart
# code by using frog's in-browser compilation. This is a minimal attempt,
# with a UI that needs a total gutting, but it gets things start in Firefox.
# Over time, I hope that Dart in FF becomes a really nice development path.

# This script first calls copy_libs.py to get the libs staged correctly.

import os
import shutil
import fileinput
import re
import subprocess
import sys

TIP_PATH = os.path.dirname(os.path.abspath(__file__))
FROG_PATH = os.path.dirname(TIP_PATH)
LIB_PATH = os.path.join(FROG_PATH, 'lib')
FFTIP_PATH = os.path.join(TIP_PATH, 'fftip')
FFTIP_CONTENT_PATH = os.path.join(FFTIP_PATH, 'chrome', 'content')
FFTIP_LIB_PATH = os.path.join(FFTIP_CONTENT_PATH, 'lib')
FFTIP_XPI = os.path.join(TIP_PATH, 'fftip.xpi')

def main():
  subprocess.call([sys.executable, './copy_libs.py'])
  if (os.path.exists(FFTIP_LIB_PATH)):
    shutil.rmtree(FFTIP_LIB_PATH)
  if (os.path.exists(FFTIP_XPI)):
    os.remove(FFTIP_XPI)
  shutil.copytree(LIB_PATH, FFTIP_LIB_PATH, 
                  ignore=shutil.ignore_patterns('.svn'))

  for file in os.listdir(TIP_PATH):
    if (file.endswith('.css') or file.endswith('.gif') or 
        file.endswith('.html') or file.endswith('.js')):
      shutil.copy(file, FFTIP_CONTENT_PATH)

  os.system('cd %s; zip --exclude=*/.svn* -r %s *' % (FFTIP_PATH, FFTIP_XPI))
  print('Generated Firefox extension at %s' % FFTIP_XPI)

if __name__ == '__main__':
  sys.exit(main())
