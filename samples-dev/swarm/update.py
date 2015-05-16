#!/usr/bin/env python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# This script builds and then uploads the Dart client sample app to AppEngine,
# where it is accessible by visiting http://dart.googleplex.com.
import os
import subprocess
import sys

from os.path import abspath, basename, dirname, exists, join, split, relpath
import base64, re, os, shutil, subprocess, sys, tempfile, optparse

APP_PATH = os.getcwd()
CLIENT_TOOLS_PATH = dirname(abspath(__file__))
CLIENT_PATH = dirname(CLIENT_TOOLS_PATH)

# Add the client tools directory so we can find htmlconverter.py.
sys.path.append(CLIENT_TOOLS_PATH)
import htmlconverter

def convertOne(infile, options):
  outDirBase = 'outcode'
  outfile = join(outDirBase, infile)
  print 'converting %s to %s' % (infile, outfile)

  if 'dart' in options.target:
    htmlconverter.convertForDartium(
        infile,
        outDirBase,
        outfile.replace('.html', '-dart.html'),
        options.verbose)
  if 'js' in options.target:
    htmlconverter.convertForChromium(
        infile, options.dartc_extra_flags,
        outfile.replace('.html', '-js.html'),
        options.verbose)


def Flags():
  """ Consturcts a parser for extracting flags from the command line. """
  result = optparse.OptionParser()
  result.add_option("-t", "--target",
      help="The target html to generate",
      metavar="[js,dart]",
      default='js,dart')
  result.add_option("--verbose",
      help="Print verbose output",
      default=False,
      action="store_true")
  result.add_option("--dartc_extra_flags",
      help="Additional flag text to pass to dartc",
      default="",
      action="store")
  #result.set_usage("update.py input.html -o OUTDIR -t chromium,dartium")
  return result

def getAllHtmlFiles():
  htmlFiles = []
  for filename in os.listdir(APP_PATH):
    fName, fExt = os.path.splitext(filename)
    if fExt.lower() == '.html':
      htmlFiles.append(filename)

  return htmlFiles

def main():
  os.chdir(CLIENT_PATH) # TODO(jimhug): I don't like chdir's in scripts...

  parser = Flags()
  options, args = parser.parse_args()
  #if len(args) < 1 or not options.out or not options.target:
  #  parser.print_help()
  #  return 1

  REL_APP_PATH = relpath(APP_PATH)
  for file in getAllHtmlFiles():
    infile = join(REL_APP_PATH, file)
    convertOne(infile, options)

if __name__ == '__main__':
  main()
