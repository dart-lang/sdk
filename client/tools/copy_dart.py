#!/usr/bin/env python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
"""Used to merge and copy dart source files for deployment to AppEngine"""

import fileinput
import sys
import shutil
import os
import re
from os.path import abspath, basename, dirname, exists, isabs, join
from glob import glob

re_library = re.compile(r'^#library\([\'"](.*)[\'"]\);$')
re_import = re.compile(r'^#import\([\'"](.*)[\'"]\);$')
re_source = re.compile(r'^#source\([\'"](.*)[\'"]\);$')

class Library(object):
  def __init__(self, name, imports, sources, code):
    self.name = name
    self.imports = imports
    self.sources = sources
    self.code = code

def parseLibrary(library):
  """ Parses a .dart source file that is the root of a library, and returns
      information about it: the name, the imports, included sources, and any
      code in the file.
  """
  libraryname = None
  imports = []
  sources = []
  inlinecode = []
  if exists(library):
    # TODO(sigmund): stop parsing when import/source
    for line in fileinput.input(library):
      match = re_import.match(line)
      if match:
        imports.append(match.group(1))
      else:
        match = re_source.match(line)
        if match:
          sources.append(match.group(1))
        else:
          match = re_library.match(line)
          if match:
            assert libraryname is None
            libraryname = match.group(1)
          else:
            inlinecode.append(line)

    fileinput.close()
  return Library(libraryname, imports, sources, inlinecode)

def normjoin(*args):
  return os.path.normpath(os.path.join(*args))

def mergefiles(srcs, dstfile):
  for src in srcs:
    with open(src, 'r') as s:
      dstfile.write(s.read())

def main(outdir = None, *inputs):
  if not outdir or not inputs:
    print "Usage: %s OUTDIR INPUTS" % args[0]
    print "  OUTDIR is the war directory to copy to"
    print "  INPUTS is a list of files or patterns used to specify the input"
    print "   .dart files"
    print "This script should be run from the client root directory."
    print "Files will be merged and copied to: OUTDIR/relative-path-of-file,"
    print "except for dart files with absolute paths, which will be copied to"
    print " OUTDIR/absolute-path-as-directories"
    return 1

  entry_libraries = []
  for i in inputs:
    entry_libraries.extend(glob(i))

  for entrypoint in entry_libraries:
    # Get the transitive set of dart files this entrypoint depends on, merging
    # each library along the way.
    worklist = [os.path.normpath(entrypoint)]
    seen = set()
    while len(worklist) > 0:
      lib = worklist.pop()
      if lib in seen:
        continue

      seen.add(lib)

      if lib.startswith('dart:'):
        continue

      if (dirname(dirname(lib)).endswith('dom/generated/src')
          or dirname(lib).endswith('dom/src')):
        continue

      if lib.endswith('json/json.dart'):
        # TODO(jmesserly): Dartium interprets "json.dart" as "dart_json.dart",
        # so we need that add dart_json.dart here. This is hacky.
        lib = lib.replace('json.dart', 'dart_json.dart')

      library = parseLibrary(lib)

      # Ensure output directory exists
      outpath = join(outdir, lib[1:] if isabs(lib) else lib)
      dstpath = dirname(outpath)
      if not exists(dstpath):
        os.makedirs(dstpath)


      # Create file containing all imports, and inlining all sources
      with open(outpath, 'w') as f:
        if library.name:
          f.write("#library('%s');\n\n" % library.name)
        else:
          f.write("#library('%s');\n\n" % basename(lib))
        for importfile in library.imports:
          f.write("#import('%s');\n" % importfile)
        f.write('%s' % (''.join(library.code)))
        mergefiles([normjoin(dirname(lib), s) for s in library.sources], f)

      worklist.extend([normjoin(dirname(lib), i) for i in library.imports])

  return 0

if __name__ == '__main__':
  sys.exit(main(*sys.argv[1:]))
