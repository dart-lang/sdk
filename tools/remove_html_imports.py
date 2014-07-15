#!/usr/bin/env python
# Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

'''Tool for removing dart:html and related imports from a library.

Copy SOURCE to TARGET, removing any lines that import dart:html.

Usage:
  python tools/remove_html_imports.py SOURCE TARGET
'''

import os
import re
import shutil
import sys

HTML_IMPORT = re.compile(r'''^import ["']dart:(html|html_common|indexed_db'''
                         r'''|js|svg|web_(audio|gl|sql))["'];$''',
                         flags=re.MULTILINE)

def main(argv):
  source = argv[1]
  target = argv[2]
  shutil.rmtree(target)
  shutil.copytree(source, target, ignore=shutil.ignore_patterns('.svn'))

  for root, subFolders, files in os.walk(target):
    for path in files:
      if not path.endswith('.dart'): next
      with open(os.path.join(root, path), 'r+') as f:
        contents = f.read()
        f.seek(0)
        f.truncate()
        f.write(HTML_IMPORT.sub(r'// import "dart:\1";', contents))

if __name__ == '__main__':
  sys.exit(main(sys.argv))
