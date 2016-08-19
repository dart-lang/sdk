#!/usr/bin/env python
#
# Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Updates the list of Observatory source files.

import os
import sys
from datetime import date

def getDir(rootdir, target):
    sources = []
    for root, subdirs, files in os.walk(rootdir):
        subdirs.sort()
        files.sort()
        for f in files:
            sources.append(root + '/' + f)
    return sources

def main():
    target = open('observatory_sources.gypi', 'w')
    target.write('# Copyright (c) ')
    target.write(str(date.today().year))
    target.write(', the Dart project authors.  Please see the AUTHORS file\n');
    target.write('# for details. All rights reserved. Use of this source code is governed by a\n');
    target.write('# BSD-style license that can be found in the LICENSE file.\n');
    target.write('\n');
    target.write('# This file contains all dart, css, and html sources for Observatory.\n');
    target.write('{\n  \'sources\': [\n')
    sources = []
    for rootdir in ['lib', 'web']:
        sources.extend(getDir(rootdir, target))
    sources.sort()
    for s in sources:
        if (s[-9:] != 'README.md'):
            target.write('    \'' + s + '\',\n')
    target.write('  ]\n}\n')
    target.close()

if __name__ == "__main__":
   main()
