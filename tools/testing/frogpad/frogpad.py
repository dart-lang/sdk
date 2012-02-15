#!/usr/bin/python

# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#

"""
Generates an html file (frogpad.html) that can be used to execute the frog
compiler in a web browser or DumpRenderTree,

The generated frogpad.html will contain:

  1. all the dart files that compose a dart program
  2. all the dart files of dart:core and other standard dart libraries
  3. frogpad.dart (compiled to javascript)

The contents of each dart file is placed in a separate <script> tag.

When the html page is loaded by a browser, the frog compiler will be invoked
and the user's dart program will be compiled to javascript.  The generated
javascript will be placed in the <pre> element with id "output".

If using DumpRenderTree, the output javascript can be obtained by dumping
the page as text and looking for the contents of the output textarea.
"""

import optparse
import os.path
import re
import sys

# Template for the html page we're going to generate.
HTML = """<html>
<head>
  <style type="text/css">
    textarea {
      width: 100%;
      height: 200px;
    }
    .label {
      margin-top: 5px;
    }
    pre {
      border: 2px solid black;
    }
  </style>
  {{script_tags}}
  <script type="text/javascript">
    if (window.layoutTestController) {
      layoutTestController.dumpAsText();
    }
  </script>
</head>
<body>
  <h1>Frogpad</h1>
  <div class="label">Input:</div>
  <textarea id="input"></textarea>
  <div class="label">Compiler Messages:</div>
  <pre id="warnings"></pre>
  <div class="label">Timing:</div>
  <pre id="timing"></pre>
  <div class="label">Output:</div>
  <pre id="output"></pre>
  <script type="text/javascript" src="frogpad.dart.js" ></script>
</body>
</html>
"""

# We use "application/inert" here to make the browser ignore the
# these script tags.  (frogpad.dart will fish out the contents as needed.)
#
SCRIPT_TAG = """<script type="application/inert" id="{{id}}">
{{contents}}
</script>
"""

# Regex that finds #import, #source and #native directives in .dart files.
#   match.group(1) = "import", "source" or "native"
#   match.group(2) = url of file being imported
DIRECTIVE_RE = re.compile(r"^#(import|source|native)\([\"']([^\"']*)[\"']")

# id of script tag that holds name of the top dart file to be compiled,
# (This file name passed will be passed to the frog compiler by frogpad.dart.)
MAIN_ID = "main_id"

DART_LIBRARIES = {
    "core": "lib/corelib.dart",
    "coreimpl": "lib/corelib_impl.dart",
    "dom": "../client/dom/frog/dom_frog.dart",
    "html": "../client/html/release/html.dart",
    "htmlimpl": "../client/html/release/htmlimpl.dart",
    "json": "../lib/json/json_frog.dart"
}


class Pad(object):
  """
  Accumulates all source files that are needed to compile a dart program,
  and places them in <script> tags on an html page.
  """

  def __init__(self, frog_dir, main_file):
    # directory of frog compiler source code
    self.frog_dir = frog_dir

    # which .dart file to compile
    self.main_file = main_file

    # map from file name to File object (contains entries for all corelib
    # and all other dart files needed to compile main_file)
    self.name_to_file = {}

    # map from script tag id to File object
    self.id_to_file = {}

    self.load_libraries()
    self.load_file(self.main_file)

  def generate_html(self):
    tags = []
    for f in self.id_to_file.values():
      tags.append(self._create_tag(f.id, f.contents))
    tags.append(self._create_tag(MAIN_ID, self.main_file))
    html = HTML.replace("{{script_tags}}", "".join(tags))
    return html

  @staticmethod
  def _create_tag(id, contents):
    s = SCRIPT_TAG
    s = s.replace("{{id}}", id)
    s = s.replace("{{contents}}", contents)
    return s

  def dart_library(self, name):
    path = DART_LIBRARIES[name]
    if not path:
      raise Exception("unrecognized 'dart:%s'", name)
    return os.path.join(self.frog_dir, path)

  def load_libraries(self):
    for name in DART_LIBRARIES:
      self.load_file(self.dart_library(name))

  def load_file(self, name):
    name = os.path.abspath(name)
    if name in self.name_to_file:
      print "already loaded %s, skipping" % name
      return
    f = File(self, name)
    self.name_to_file[f.name] = f
    if f.id in self.id_to_file:
      raise Exception("ambiguous id '%s'" % f.id)
    self.id_to_file[f.id] = f
    f.directives()

class File(object):
  def __init__(self, pad, name):
    self.pad = pad
    self.name = name
    self.id = self._make_id()
    if not os.path.exists(name):
      raise Exception("cannot find file '%s'" % name)
    with open(self.name, "r") as f:
      self.contents = f.read()
    print "creating File '%s' (%d lines)" % (self.name, len(self.contents))

  def _make_id(self):
    """
    Generates an id (based on the file name) for the <script> tag that will
    hold the contents of this file.
    """
    (dirname, name) = os.path.split(self.name)
    dirname = os.path.basename(dirname)
    name = name.replace(".", "_")
    return dirname + "_" + name

  def directives(self):
    """Load files referenced by #source, #import and #native directives."""
    lines = self.contents.split("\n")
    self.line_number = 0
    for line in lines:
      self.line_number += 1
      self._directive(line)

  def _directive(self, line):
    match = DIRECTIVE_RE.match(line)
    if not match:
      return
    url = match.group(2)
    if url.startswith("dart:"):
      path = self.pad.dart_library(url[len("dart:"):])
    else:
      path = os.path.join(os.path.dirname(self.name), url)
    self.pad.load_file(path)


def main(argv):
  parser = optparse.OptionParser()
  parser.add_option("-o", "--out", dest="out_file")

  (options, args) = parser.parse_args(argv)
  main_file = os.path.abspath(args[1])

  script_dir = os.path.abspath(os.path.dirname(argv[0]))
  frog_dir = os.path.abspath(os.path.join(script_dir, "../../../frog"))

  pad = Pad(frog_dir, main_file)
  html = pad.generate_html()

  filename = "frogpad.html"
  with open(filename, "w") as output:
    output.write(html)
  print "generated '%s' (%d bytes)" % (filename, len(html))

if __name__ == "__main__":
  sys.exit(main(sys.argv))

