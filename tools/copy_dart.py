#!/usr/bin/env python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
"""Used to merge and copy dart source files for deployment to AppEngine"""

import fileinput
import sys
import os
import re
from os.path import basename, dirname, exists, isabs, join
from glob import glob

re_directive = re.compile(
    r'^(library|import|part|native|resource)\s+(.*);$')
re_comment = re.compile(
    r'^(///|/\*| \*).*$')

class Library(object):
  def __init__(self, name, imports, sources, natives, code, comment):
    self.name = name
    self.imports = imports
    self.sources = sources
    self.natives = natives
    self.code = code
    self.comment = comment

def parseLibrary(library):
  """ Parses a .dart source file that is the root of a library, and returns
      information about it: the name, the imports, included sources, and any
      code in the file.
  """
  libraryname = None
  imports = []
  sources = []
  natives = []
  inlinecode = []
  librarycomment = []
  if exists(library):
    # TODO(sigmund): stop parsing when import/source
    for line in fileinput.input(library):
      match = re_directive.match(line)
      if match:
        directive = match.group(1)
        if directive == 'library':
          assert libraryname is None
          libraryname = match.group(2)
        elif directive == 'part':
          suffix = match.group(2)
          if not suffix.startswith('of '):
            sources.append(match.group(2).strip('"\''))
        elif directive == 'import':
          imports.append(match.group(2))
        else:
          raise Exception('unknown directive %s in %s' % (directive, line))
      else:
        # Check for library comment.
        if not libraryname and re_comment.match(line):
          librarycomment.append(line)
        else:
          inlinecode.append(line)
    fileinput.close()
  return Library(libraryname, imports, sources, natives, inlinecode,
                 librarycomment)

def normjoin(*args):
  return os.path.normpath(os.path.join(*args))

def mergefiles(srcs, dstfile):
  for src in srcs:
    with open(src, 'r') as s:
      for line in s:
        if not line.startswith('part of '):
          dstfile.write(line)

def main(outdir = None, *inputs):
  if not outdir or not inputs:
    print "Usage: %s OUTDIR INPUTS" % sys.argv[0]
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

      if (dirname(dirname(lib)).endswith('dom/generated/src')
          or dirname(lib).endswith('dom/src')):
        continue

      library = parseLibrary(lib)

      # Ensure output directory exists
      outpath = join(outdir, lib[1:] if isabs(lib) else lib)
      dstpath = dirname(outpath)
      if not exists(dstpath):
        os.makedirs(dstpath)


      # Create file containing all imports, and inlining all sources
      with open(outpath, 'w') as f:
        if library.name:
          if library.comment:
            f.write('%s' % (''.join(library.comment)))
          f.write("library %s;\n\n" % library.name)
        else:
          f.write("library %s;\n\n" % basename(lib))
        for importfile in library.imports:
          f.write("import %s;\n" % importfile)
        f.write('%s' % (''.join(library.code)))
        mergefiles([normjoin(dirname(lib), s) for s in library.sources], f)

      for suffix in library.imports:
        m = re.match(r'[\'"]([^\'"]+)[\'"](\s+as\s+\w+)?.*$', suffix)
        uri = m.group(1)
        if not uri.startswith('dart:'):
          worklist.append(normjoin(dirname(lib), uri))

  return 0

if __name__ == '__main__':
  sys.exit(main(*sys.argv[1:]))
