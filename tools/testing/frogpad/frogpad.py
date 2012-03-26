#!/usr/bin/env python

# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#

"""
Frogpad is used to compile .dart files to javascript.

This is accomplished by first creating an html file (usually called
<something>.frogpad.html) that can be used to execute the frog compiler in
a web browser (or DumpRenderTree).

The generated frogpad.html contains:

  1. all the dart files that compose a dart program
  2. all the dart files of dart:core and other standard dart libraries
  3. frogpad.dart (compiled to javascript)

The contents of each dart file is placed in a separate <script> tag.

When the html page is loaded by a browser, the frog compiler is invoked
and the dart program is compiled to javascript.  The generated javascript is
placed in a <pre> element with id "output".

When the html page is passed to DumpRenderTree, the dumped output will
have the generated javascript.
"""

import logging
import optparse
import os.path
import platform
import re
import subprocess
import sys


class FileNotFoundException(Exception):
  def __init__(self, file_name):
    self._name = file_name

  def __str__(self):
    return self._name


class CommandFailedException(Exception):
  def __init__(self, message):
    self._message = message

  def GetMessage(self):
    return self._message


# Template for the html page we're going to generate.
HTML = """<!DOCTYPE html>
<html>
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
  <script type="text/javascript">
    {{FROGPAD_JS}}
  </script>
</body>
</html>
"""

# This finds everything after the word "Output:" in the html page.
# (Note, because the javascript we're fishing out spans multiple lines
# we need to use the DOTALL switch here.)
OUTPUT_JAVASCRIPT_REGEX = re.compile(".*\nOutput:\n(.*)\n#EOF", re.DOTALL)

# If the frogpad.dart encounters a compilation error, the generated
# javascript will start with the word 'throw'.
COMPILATION_ERROR_REGEX = re.compile(".*frogpad compilation error.*", re.DOTALL)

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

# id of the script tag that holds the name of the frog directory
FROGDIR_ID = "frogdir_id"

DART_LIBRARIES = {
    "core": "lib/corelib.dart",
    "coreimpl": "lib/corelib_impl.dart",
    "dom": "../lib/dom/frog/dom_frog.dart",
    "html": "../lib/html/frog/html_frog.dart",
    "isolate": "../lib/isolate/isolate_frog.dart",
    "json": "../lib/json/json_frog.dart"
}

class Pad(object):
  """
  Accumulates all source files that are needed to compile a dart program,
  and places them in <script> tags on an html page.
  """

  def __init__(self, argv):
    parser = optparse.OptionParser(usage=
      "%prog [options] file_to_compile.dart"
    )
    parser.add_option("-f", "--frogpad_js",
        help="location of frogpad.js file")
    parser.add_option("-o", "--out",
        help="name of javascript output file")
    parser.add_option("-v", "--verbose", action="store_true",
        help="more verbose logging")
    (options, args) = parser.parse_args(argv)

    log_level = logging.INFO
    if options.verbose:
      log_level = logging.DEBUG
    logging.basicConfig(level=log_level)

    if len(args) < 2:
      parser.print_help()
      sys.exit(1)

    self.main_file = os.path.abspath(args[1])

    # directory of this script
    self.frogpad_dir = os.path.abspath(os.path.dirname(argv[0]))

    # root of dart source repo
    self.dart_dir = os.path.dirname(os.path.dirname(os.path.dirname(
        self.frogpad_dir)))

    # directory of frog compiler source code
    self.frog_dir = os.path.join(self.dart_dir, "frog")

    logging.debug("dartdir_dir: '%s'" % self.dart_dir)
    logging.debug("frog_dir: '%s'" % self.frog_dir)
    logging.debug("frogpad_dir: '%s'" % self.frogpad_dir)

    # location of frogpad.js
    # (frogpad.js is generated by running frogsh_bootstrap_wrapper.py)
    if not options.frogpad_js:
      raise Exception("--frogpad_js is required")

    if not os.path.exists(options.frogpad_js):
      raise FileNotFoundException(options.frogpad_js)

    self.frogpad_js = options.frogpad_js

    if options.out:
      # user has specified an output file name
      self.js_file = os.path.abspath(options.out)
    else:
      # User didn't specify an output file, so use the input
      # file name as the base of the output file name.
      self.js_file = self.main_file + ".frogpad.js"

    logging.debug("js_file: '%s" % self.js_file)

    # this is the html file that we pass to DumpRenderTree
    self.html_file = self.js_file + ".frogpad.html"
    logging.debug("html_file: '%s'" % self.html_file)

    # map from file name to File object (contains entries for all corelib
    # and all other dart files needed to compile main_file)
    self.name_to_file = {}

    # map from script tag id to File object
    self.id_to_file = {}

    self.load_libraries()
    self.load_file(self.main_file)

    html = self.generate_html()
    write_file(self.html_file, html)

    js = self.generate_js()
    write_file(self.js_file, js)

    line_count = len(js.splitlines())
    logging.debug("generated '%s' (%d lines)", self.js_file, line_count)

    match = COMPILATION_ERROR_REGEX.match(js)
    if match:
      sys.exit(1)

  def generate_html(self):
    tags = []
    for f in self.id_to_file.values():
      tags.append(self._create_tag(f.id, f.contents))
    tags.append(self._create_tag(MAIN_ID, self.main_file))
    tags.append(self._create_tag(FROGDIR_ID, self.frog_dir))
    html = HTML.replace("{{script_tags}}", "".join(tags))
    html = html.replace("{{FROGPAD_JS}}", read_file(self.frogpad_js))
    return html

  def generate_js(self):
    drt = os.path.join(self.dart_dir, "client/tests/drt/DumpRenderTree")
    if platform.system() == 'Darwin':
      drt += ".app"
    elif platform.system() == 'Windows':
      raise Exception("frogpad does not run on Windows")

    check_exists(drt)
    args = []
    args.append(drt)
    args.append(self.html_file)

    stdout = run_command(args)
    match = OUTPUT_JAVASCRIPT_REGEX.match(stdout)
    if not match:
      raise Exception("can't find regex in DumpRenderTree output")
    return match.group(1)

  @staticmethod
  def _create_tag(id, contents):
    s = SCRIPT_TAG
    s = s.replace("{{id}}", id)
    # TODO(mattsh) - need to html escape here
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
    check_exists(name)
    with open(self.name, "r") as f:
      self.contents = f.read()

  def _make_id(self):
    """
    Generates an id (based on the file name) for the <script> tag that will
    hold the contents of this file.
    """
    return self.name.replace("/", "_").replace(".", "_")

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

def read_file(file_name):
  check_exists(file_name)
  with open(file_name, "r") as input:
    contents = input.read()
  logging.debug("read_file '%s' (%d bytes)" % (file_name, len(contents)))
  return contents

def write_file(file_name, contents):
  with open(file_name, "w") as output:
    output.write(contents)

  check_exists(file_name)
  logging.debug("write_file '%s' (%d bytes)" % (file_name, len(contents)))


def check_exists(file_name):
  if not os.path.exists(file_name):
    raise FileNotFoundException(file_name)


def format_command(args):
  return ' '.join(args)


def run_command(args):
  """
  Args:
    command: comamnd with arguments to exec
  Returns:
    all output that this command sent to stdout
  """

  command = format_command(args)
  logging.info("RUNNING: '%s'" % command)
  child = subprocess.Popen(args,
      stdout=subprocess.PIPE,
      stderr=subprocess.PIPE,
      close_fds=True)
  (stdout, stderr) = child.communicate()
  exit_code = child.wait()
  if exit_code:
    for line in stderr.splitlines():
      logging.info(line)
    msg = "FAILURE (exit_code=%d): '%s'" % (exit_code, command)
    logging.error(msg)
    raise CommandFailedException(msg)
  logging.debug("SUCCEEDED (%d bytes)" % len(stdout))
  return stdout


def main(argv):
  Pad(argv)

if __name__ == "__main__":
  sys.exit(main(sys.argv))
