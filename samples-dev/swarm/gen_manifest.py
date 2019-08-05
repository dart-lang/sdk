# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

#!/usr/bin/python2.6
#
"""
Usage: gen_manifest.py DIRECTORY EXTENSIONS CACHE-FILE HTML-FILES...

Outputs an app cache manifest file including (recursively) all files with the
provided in the directory with the given extensions. Each html files is then
processed and a corresponding <name>-cache.html file is created, pointing at
the appropriate cache manifest file, which is saved as <name>-cache.manifest.

Example:
gen_manifest.py war *.css,*.html,*.js,*.png cache.manifest foo.html bar.html

Produces: foo-cache.html, bar-cache.html, and cache.manifest
"""

import fnmatch
import os
import random
import sys
import datetime

cacheDir = sys.argv[1]
extensions = sys.argv[2].split(',')
manifestName = sys.argv[3]
htmlFiles = sys.argv[4:]

os.chdir(cacheDir)
print "Generating manifest from root path: " + cacheDir

patterns = extensions + htmlFiles


def matches(file):
    for pattern in patterns:
        if fnmatch.fnmatch(file, pattern):
            return True
    return False


def findFiles(rootDir):
    for root, dirs, files in os.walk(rootDir):
        for f in files:
            # yields this file relative to the given directory
            yield os.path.join(root, f)[(len(rootDir) + 1):]


manifest = []
manifest.append("CACHE MANIFEST")

# print out a random number to force the browser to update the cache manifest
manifest.append("# %s" % datetime.datetime.now().isoformat())

# print out each file to be included in the cache manifest
manifest.append("CACHE:")

manifest += (f for f in findFiles('.') if matches(f))

# force the browser to request any other files over the network,
# even when offline (better failure mode)
manifest.append("NETWORK:")
manifest.append("*")

with open(manifestName, 'w') as f:
    f.writelines(m + '\n' for m in manifest)

print "Created manifest file: " + manifestName

for htmlFile in htmlFiles:
    cachedHtmlFile = htmlFile.replace('.html', '-cache.html')
    text = open(htmlFile, 'r').read()
    text = text.replace('<html>', '<html manifest="%s">' % manifestName, 1)
    with open(cachedHtmlFile, 'w') as output:
        output.write(text)
    print "Processed html file: %s -> %s" % (htmlFile, cachedHtmlFile)

print "Successfully generated manifest and html files"
