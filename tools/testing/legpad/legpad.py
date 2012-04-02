#!/usr/bin/env python

# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""
Legpad is used to compile .dart files to javascript, using the dart2js compiler.

This is accomplished by creating an html file (usually called
<something>.legpad.html) that executes the dart2js compiler when the page
is loaded by a web browser (or DumpRenderTree).

The <something>.legpad.html file contains:

  1. all the dart files that compose a user's dart program
  2. all the dart files of dart:core and other standard dart libraries
      (or any other symbol that can follow "dart:" in an import statement
  3. legpad.dart (compiled to javascript)

The contents of each dart file is placed in a separate <script> tag.

When the html page is loaded by a browser, the leg compiler is invoked
and the dart program is compiled to javascript.  The generated javascript is
placed in a <pre> element with id "output".

When the html page is passed to DumpRenderTree, the dumped output will
have the generated javascript.

See 'example.sh' for an example of how to run legpad.
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


# Template for the legpad.html page we're going to generate.
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
  <h1>Legpad</h1>
  <div class="label">Input:</div>
  <textarea id="input"></textarea>
  <div class="label">Compiler Messages:</div>
  <pre id="warnings"></pre>
  <div class="label">Timing:</div>
  <pre id="timing"></pre>
  <div class="label">Output:</div>
  <pre id="output"></pre>
  <script type="text/javascript">
    {{LEGPAD_JS}}
  </script>
</body>
</html>
"""

# This finds everything after the word "Output:" in the html page.
# (Note, because the javascript we're fishing out spans multiple lines
# we need to use the DOTALL switch here.)
OUTPUT_JAVASCRIPT_REGEX = re.compile(".*\nOutput:\n(.*)\n#EOF", re.DOTALL)

# If the legpad.dart encounters a compilation error, the generated
# javascript will contains the words "dart2js compilation error".
COMPILATION_ERROR_REGEX = re.compile(".*dart2js compilation error.*", re.DOTALL)

# We use "application/inert" here to make the browser ignore the
# these script tags.  (legpad.dart will fish out the contents as needed.)
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
# (This file name passed will be passed to the leg compiler by legpad.dart.)
MAIN_ID = "main_id"

# TODO(mattsh): read this from some config file once ahe/zundel create it
DART_LIBRARIES = {
    "core" :      "lib/compiler/implementation/lib/core.dart",
    "coreimpl" :  "lib/compiler/implementation/lib/coreimpl.dart",
    "dom" :       "lib/dom/frog/dom_frog.dart",
    "html" :      "lib/html/frog/html_frog.dart",
    "io" :        "lib/compiler/implementation/lib/io.dart",
    "isolate" :   "lib/isolate/isolate_leg.dart",
    "json" :      "lib/json/json.dart",
    "uri" :       "lib/uri/uri.dart",
    "utf" :       "lib/utf/utf.dart",
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
    self.legpad_dir = os.path.abspath(os.path.dirname(argv[0]))

    # root of dart source repo
    self.dart_dir = os.path.dirname(os.path.dirname(os.path.dirname(
        self.legpad_dir)))

    logging.debug("dart_dir: '%s'" % self.dart_dir)

    if options.out:
      # user has specified an output file name
      self.js_file = os.path.abspath(options.out)
    else:
      # User didn't specify an output file, so use the input
      # file name as the base of the output file name.
      self.js_file = self.main_file + ".legpad.js"

    logging.debug("js_file: '%s" % self.js_file)

    # this is the html file that we pass to DumpRenderTree
    self.html_file = self.main_file + ".legpad.html"
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
    tags.append(self._create_tag(MAIN_ID, self.shorten(self.main_file)))
    html = HTML.replace("{{script_tags}}", "".join(tags))

    legpad_js = os.path.join(self.legpad_dir, "legpad.dart.js")
    check_exists(legpad_js)

    html = html.replace("{{LEGPAD_JS}}", read_file(legpad_js))
    return html

  def generate_js(self):
    drt = os.path.join(self.dart_dir, "client/tests/drt/DumpRenderTree")
    if platform.system() == 'Darwin':
      drt += ".app"
    elif platform.system() == 'Windows':
      raise Exception("legpad does not run on Windows")

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
    return os.path.join(self.dart_dir, path)

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

  def shorten(self, name):
    """
    Change that full path of the dart svn repo to simply "dartdir"
    """
    return name.replace(self.dart_dir, "dartdir")

  def make_id(self, name):
    """
    Generates an id (based on the file name) for the <script> tag that will
    hold the contents of this file.
    """
    return self.shorten(name).replace("/", "_").replace(".", "_")


class File(object):
  def __init__(self, pad, name):
    self.pad = pad
    self.name = name
    self.id = pad.make_id(name)
    check_exists(name)
    with open(self.name, "r") as f:
      self.contents = f.read()

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
