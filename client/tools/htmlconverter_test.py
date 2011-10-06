# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

#!/usr/bin/env python
#

"""A test for htmlconverter.py
"""

from os.path import abspath, basename, dirname, exists, join, split
import optparse
import os
import sys
import subprocess

# The inputs to our test
TEST1_HTML = """
<html>
  <head></head>
  <body>
    <script type="application/javascript">
      if (window.layoutTestController) {
        window.layoutTestController.dumpAsText();
      }
    </script>

    <!-- embed source code -->
    <script type="application/dart">
      main() {
        window.alert('hi');
      }
    </script>
  </body>
</html>
"""

TEST1_OUTPUT = """
ALERT: hi
Content-Type: text/plain

#EOF
"""

TEST2_HTML = """
<html>
  <head></head>
  <body>
    <script type="application/javascript">
      if (window.layoutTestController) {
        window.layoutTestController.dumpAsText();
      }
    </script>

    <!-- embed source code -->
    <script type="application/dart" src="test_2.dart"></script>
  </body>
</html>
"""

TEST2_DART = """
#library('test2');
#import('dart:dom');
main() {
  window.alert('test2!');
}
"""

TEST2_OUTPUT = """
ALERT: test2!
Content-Type: text/plain

#EOF
"""

TEST3_HTML = """
<html>
  <head></head>
  <body>
    <script type="application/javascript">
      if (window.layoutTestController) {
        window.layoutTestController.dumpAsText();
      }
    </script>

    <!-- embed source code -->
    <script type="application/dart" src="test_3.dart"></script>
  </body>
</html>
"""

TEST3_DART = """
#import('dart:dom');
#source('test_3a.dart');
#source('test_3b.dart');
"""

TEST3_DART_A = """
class MyClass {
  static myprint() {
    window.alert('test3!');
  }
}
"""

TEST3_DART_B = """
main() {
  MyClass.myprint();
}
"""

TEST3_OUTPUT = """
ALERT: test3!
Content-Type: text/plain

#EOF
"""

TEST4_HTML = """
<html>
  <head></head>
  <body>
    <script type="application/javascript">
      if (window.layoutTestController) {
        window.layoutTestController.dumpAsText();
      }
    </script>

    <script type="application/dart" src="test_4.dart"></script>
  </body>
</html>
"""

TEST4_DART = """
#import('dart:dom');
#import('observable/observable.dart');

main() {
  // use imported code
  var arr = new ObservableList();
  arr.addChangeListener((EventSummary events) {
    var t = ['update', 'add   ',
             'remove', 'global'][events.events[0].type];
    var o = events.events[0].oldValue;
    o = (o != null ? o : '_');
    var n = events.events[0].newValue;
    n = (n != null ? n : '_');
    window.alert(" " + t + " " + o + " -> " + n);
  });
  EventBatch.wrap((e) { arr.add(3); })(null);
  EventBatch.wrap((e) { arr.add(2); })(null);
  EventBatch.wrap((e) { arr.add(1); })(null);
  EventBatch.wrap((e) { arr[0] = 5; })(null);
  EventBatch.wrap((e) { arr[2] = 0; })(null);
  EventBatch.wrap((e) { arr.removeAt(1); })(null);
  EventBatch.wrap((e) { arr.clear(); })(null);
}
"""

# Expected output when run in DumpRenderTree
TEST4_OUTPUT = """
ALERT:  add    _ -> 3
ALERT:  add    _ -> 2
ALERT:  add    _ -> 1
ALERT:  update 3 -> 5
ALERT:  update 1 -> 0
ALERT:  remove 2 -> _
ALERT:  global _ -> _
Content-Type: text/plain

#EOF
"""

TEST5_HTML = """
<html>
  <head></head>
  <body>
    <script type="application/javascript">
      if (window.layoutTestController) {
        window.layoutTestController.dumpAsText();
      }
    </script>

    <!-- embed source code -->
    <script type="application/dart">
      main() {
        var element = document.getElementById("test5div");
        if (element == null) {
          window.alert("this script shoulnd't be run synchronously");
        } else {
          window.alert(element.innerHTML);
        }
      }
    </script>
    <div id="test5div">this is visible on DOMContentLoaded</div>
  </body>
</html>
"""

TEST5_OUTPUT = """
ALERT: this is visible on DOMContentLoaded
Content-Type: text/plain
this is visible on DOMContentLoaded
#EOF
"""

# TODO(sigmund): integrate with testing infrastructure and mark negative tests.
# removing the prefix on test6 should purposely fail.

TEST6_HTML = """
<html>
  <head></head>
  <body>
    <script type="application/javascript">
      if (window.layoutTestController) {
        window.layoutTestController.dumpAsText();
      }
    </script>

    <!-- embed source code -->
    <script type="application/dart">
      #import('html/html.dart', prefix: 'html');
      main() {
        html.window.alert('hi');
      }
    </script>
  </body>
</html>
"""

TEST6_OUTPUT = """
ALERT: hi
Content-Type: text/plain

#EOF
"""


FILES = {
    'test_1.html': TEST1_HTML,

    'test_2.html': TEST2_HTML,
    'test_2.dart': TEST2_DART,

    'test_3.html': TEST3_HTML,
    'test_3.dart': TEST3_DART,
    'test_3a.dart': TEST3_DART_A,
    'test_3b.dart': TEST3_DART_B,

    'test_4.html': TEST4_HTML,
    'test_4.dart': TEST4_DART,

    'test_5.html': TEST5_HTML,
    'test_6.html': TEST6_HTML,
  }

INPUTS = [
    'test_1.html',
    'test_2.html',
    'test_3.html',
    'test_4.html',
    'test_5.html',
    'test_6.html'
    ]

OUTPUTS = [
    TEST1_OUTPUT,
    TEST2_OUTPUT,
    TEST3_OUTPUT,
    TEST4_OUTPUT,
    TEST5_OUTPUT,
    TEST6_OUTPUT
    ]

CLIENT_PATH = dirname(dirname(abspath(__file__)))
RED_COLOR = "\033[31m"
GREEN_COLOR = "\033[32m"
YELLOW_COLOR = "\033[33m"
NO_COLOR = "\033[0m"

last_line_length = 0
def printLine(s):
  """ Prints a line in place (erasing the previous line). """
  global last_line_length
  s = " Testing htmlconverter.py: " + s
  if last_line_length > 0:
    print "\r" + (" " * last_line_length) + "\r",
  last_line_length = len(s)
  print s,
  sys.stdout.flush()

def execute(cmd, verbose=False):
  """Execute a command in a subprocess. """
  if verbose: print 'Executing: ' + ' '.join(cmd)
  pipe = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  output, err = pipe.communicate()
  if pipe.returncode != 0:
    print 'Execution failed: ' + output + '\n' + err
  if verbose or pipe.returncode != 0:
    print output
    print err
  return pipe.returncode, output, err

def browserRun(message, htmlfile, test, verbose):
  # run the generated code
  printLine(message + ' [%d]' % (test + 1))
  status, out, err = execute([
      'tests/drt/DumpRenderTree',
       '--dart-flags=--enable_type_checks --enable_asserts', htmlfile],
      verbose)
  if status != 0:
    printLine("%sERROR%s test output [%d]" % (RED_COLOR, NO_COLOR, test + 1))
    return status

  # check that the output is equivalent and cleanup
  out = '\n' + out
  if out == OUTPUTS[test]:
    printLine("%sPASS%s [%d]" % (GREEN_COLOR, NO_COLOR, test + 1))
  else:
    printLine("%sFAIL%s [%d]" % (RED_COLOR, NO_COLOR, test + 1))
    print out
    print err
    return 1

  return 0

def createInputFiles():
  printLine("... creating input files")
  for filename in FILES:
    with open(filename, 'w') as f:
      f.write(FILES[filename])

def deleteInputFiles():
  for filename in FILES:
    os.remove(filename)

def runTest(test, target, verbose, keep_temporary_files):
  inputfile = INPUTS[test]
  suffix = '-js.html' if target == 'chromium' else '-dart.html'
  outfile = abspath(join('out', inputfile.replace(".html", suffix)))

  # TODO(sigmund): tests should also run in dartium before converting them

  # run the htmlconverter.py script on it
  printLine("... converting input html [%d]" % (test + 1))
  cmd = [sys.executable, 'tools/htmlconverter.py', inputfile,
         '-o', 'out/', '-t', target]
  if verbose: cmd.append('--verbose')
  status, out, err = execute(cmd, verbose)
  if status != 0:
    printLine("%sERROR%s converting [%d]" % (RED_COLOR, NO_COLOR, test + 1))
    print out
    print err
    return status

  status = browserRun(
      "... running compiled html in %s" % target, outfile, test, verbose)
  if not keep_temporary_files:
    os.remove(outfile)
  return status

def Flags():
  """ Consturcts a parser for extracting flags from the command line. """
  result = optparse.OptionParser()
  result.add_option("--keep_temporary_files",
      help="Keep temporary files created for each test",
      default=False,
      action="store_true")
  result.add_option("-v", "--verbose",
      help="Print verbose output",
      default=False,
      action="store_true")
  result.add_option("-t", "--target",
      help="The target html to generate",
      metavar="[chromium,dartium]",
      default='chromium,dartium')
  result.set_usage("htmlconverter_test.py [--verbose -t chromium,dartium]")
  return result

def shouldRunTest(test, prefixes):
  if len(prefixes) == 0:
    return True
  for a in prefixes:
    if INPUTS[test].startswith(a):
      return True
  return False


def main():
  os.chdir(CLIENT_PATH)
  parser = Flags()
  options, args = parser.parse_args()
  verbose = options.verbose
  keep_temporary_files = options.keep_temporary_files

  createInputFiles()
  for test in range(len(INPUTS)):
    if shouldRunTest(test, args):
      if 'chromium' in options.target:
        if runTest(test, 'chromium', verbose, keep_temporary_files) != 0:
          if not keep_temporary_files:
            deleteInputFiles()
          return 1
      if 'dartium' in options.target:
        if runTest(test, 'dartium', verbose, keep_temporary_files) != 0:
          if not keep_temporary_files:
            deleteInputFiles()
          return 1

  if not keep_temporary_files:
    deleteInputFiles()
  return 0


if __name__ == '__main__':
  sys.exit(main())
