# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

#!/usr/bin/python2.4
#

"""Uses jscoverage to instrument a web unit test and runs it.

Uses jscoverage to instrument a web unit test and extracts coverage statistics
from running it in a headless webkit browser.
"""

import codecs
import json
import optparse
import os
import re
import sourcemap # located in this same directory
import subprocess
import sys

def InstrumentScript(script_name, src_dir, dst_dir, jscoveragecmd, verbose):
  """ Instruments a test using jscoverage.

      Args:
        script_name: the original javascript file containing the test.
        src_dir: the directory where the test is found.
        dst_dir: the directory where to place the instrumented test.
        jscoveragecmd: the fully-qualified command to run jscoverage.

      Returns:
        0 if no errors where found.
        1 if jscoverage gave errors.
  """
  SafeMakeDirs(dst_dir)

  PrintNewStep("instrumenting")
  src_file = os.path.join(src_dir, script_name)
  dst_file = os.path.join(dst_dir, script_name)
  if not os.path.exists(src_file):
    print "Script not found: " + src_file
    return 1

  if os.path.exists(dst_file):
    if os.path.getmtime(src_file) < os.path.getmtime(dst_file):
      # Skip running jscoverage if the input hasn't been updated
      return 0

  # Create the instrumented code using jscoverage:
  status, output, err = ExecuteCommand([sys.executable,
      'tools/jscoverage_wrapper.py', jscoveragecmd, src_file, dst_dir], verbose)
  if status:
    print "ERROR: jscoverage had errors: "
    print output
    print err
    return 1
  return 0

def SafeMakeDirs(dirname):
  """ Creates a directory and, if necessary its parent directories.

  This function will safely return if other concurrent jobs try to create the
  same directory.
  """
  if not os.path.exists(dirname):
    try:
      os.makedirs(dirname)
    except Exception:
      # this check allows invoking this script concurrently in many jobs
      if not os.path.exists(dirname):
        raise

COVERAGE_TEST_TEMPLATE = '''
<html>
<head>
  <title> Coverage for %s </title>
</head>
<body>
  <h1> Running %s </h1>
  <script type="text/javascript" src="%s"></script>
  <script type="text/javascript" src="%s"></script>
</body>
</html>
'''

def CollectCoverageForTest(test, controller, script, drt, src_dir,
                           dst_dir, sourcemapfile, result, verbose):
  """ Collect test coverage information from an instrumented test.
      Internally this function generates an html page for collecting the
      coverage results. This page is just like the HTML that runs a test, but
      instead of using 'test_controller.js' (which indicates whether tests pass
      or fail), we use 'coverage_controller.js' (which prints out coverage
      information).

      Args:
        test: the name of the test
        controller: path to coverage_controller.js
        script: actual javascript test (previously instrumented with jscoverage)
        drt: path to DumpRenderTree
        src_dir: directory where original 'script' is found.
        dst_dir: directory where the instrumented 'script' is found and where to
                 generate the html file.
        sourcemapfile: sourcemap file associated with the script test. This is
                       typically the source map for the original
                       (non-instrumented code) since the jscoverage results are
                       reported with respect to the original line numbers.
        result: a dictionary that wlll hold the results of this invocation. The
                dictionary keys are original dart file names, the value is a
                pair containing two sets of numbers: covered lines, and
                non-covered but executable lines. Note, some lines are not
                mentioned because they could be dropped during compilation (e.g.
                empty lines, comments, etc).
                This dictionary doesn't need to be empty, in which case this
                function will combine the results of this test with what
                previously was recoded in 'result'.
        verbose: show verbose progress mesages
  """
  html_contents = COVERAGE_TEST_TEMPLATE % (test, test, controller, script)
  html_output_file = os.path.join(dst_dir, test + '_coverage.html')
  with open(html_output_file, 'w') as f:
    f.write(html_contents)

  PrintNewStep("running")
  status, output, err = ExecuteCommand([drt, html_output_file], verbose)
  lines = output.split('\n')
  if len(lines) <= 2 or status:
    print "ERROR: can't obtain coverage for %s%s%s" % (
        RED_COLOR, html_output_file, NO_COLOR)
    return 1 if not status else status

  PrintNewStep("processing")
  # output is json, possibly split in multiple lines. We skip the first line
  # (DumpRenderTree shows a content-type line).
  coverage_res = ''.join(lines[1: lines.index("#EOF")])
  try:
    json_obj = json.loads(coverage_res)
  except Exception:
    print "ERROR: can't obtain coverage for %s%s%s" % (
        RED_COLOR, html_output_file, NO_COLOR)
    return 1
  _processResult(json_obj, script, src_dir, sourcemapfile, result)


# Patterns used to detect declaration sites in the generated js code
HOIST_FUNCTION_PATTERN = re.compile("^function ")
MEMBER_PATTERN = re.compile(
    "[^ ]*prototype\.[^ ]*\$member = function\([^\)]*\){$")
GETTER_PATTERN = re.compile(
    "[^ ]*prototype\.[^ ]*\$getter = function\([^\)]*\){$")
SETTER_PATTERN = re.compile(
    "[^ ]*prototype\.[^ ]*\$setter = function\([^\)]*\){$")

def _processResult(json_obj, js_file, src_dir, sourcemap_file, result):
  """ Process the result of a single test run. See 'CollectCoverageForTest' for
      more details.

      Args:
        json_obj: the json object that was exported by coverage_controller.js
        js_file: name of the script file
        src_dir: directory where the generated jsfile is located of the script
        sourcemap_file: sourcemap file associated with the script test.
        result: a dictionary that will hold the results of this invocation.
  """
  if js_file not in json_obj or len(json_obj) != 1:
    raise Exception("broken format in coverage result")

  lines_covered = json_obj[js_file]
  smap = sourcemap.parse(sourcemap_file)
  with open(os.path.join(src_dir, js_file), 'r') as f:
    js_code = f.readlines()

  for line in range(len(lines_covered)):
    original = smap.get_source_location(line, 1)
    if original:
      filename, srcline, srccolumn, srcid = original
      if filename not in result:
        result[filename] = (set(), set())
      if lines_covered[line] is not None:
        if lines_covered[line] > 0:
          # exclude the line if it looks like a generated class declaration or
          # a method declaration
          srccode = js_code[line - 1]
          if (HOIST_FUNCTION_PATTERN.match(srccode) is None
              and GETTER_PATTERN.match(srccode) is None
              and SETTER_PATTERN.match(srccode) is None
              and MEMBER_PATTERN.match(srccode) is None):
            result[filename][0].add(srcline)
        elif lines_covered[line] == 0:
          result[filename][1].add(srcline)

# Global color constants
GREEN_COLOR = "\033[32m"
YELLOW_COLOR = "\033[33m"
RED_COLOR = "\033[31m"
NO_COLOR = "\033[0m"

# Templates for the HTML output
SUMMARY_TEMPLATE = '''<html>
  <head>
  <style>
  %s
  </style>
  </head>
  <body>
  <script type="application/javascript">
  %s
  </script>
  <script type="application/javascript">
    var files = []
    var code = {}
    var summary = {}
    %s

    render(files, code, summary);
  </script>
  </body>
</html>
'''

# Template for exporting the coverage information data for each file
FILE_TEMPLATE = '''
    // file %s
    files.push("%s");
    code["%s"] = [%s];
    summary["%s"] = [%s];'''

# TODO(sigmund): increase these thresholds to 95 and 70
GOOD_THRESHOLD = 80
OK_THRESHOLD = 50

def ReportSummary(outdir, result):
  """ Analyzes the results and produces an ASCII and an HTML summary report.
      Args:
        outdir: directory where to generate the HTML report
        result: a dictionary containing results of the coverage analysis. The
                dictionary maps file names to a pair of 2 sets of numbers. The
                first set contains executable covered lines, the second set
                contains executable non-covered lines. Any missing line is
                likely not translated into code (e.g. comments, an interface
                body) or translated into declarations (e.g. a getter
                declaration).
  
  """
  basepath = os.path.join(os.path.dirname(sys.argv[0]), "../")
  html_summary_lines = []
  print_summary_lines = []
  for key in result.keys():
    filepath = os.path.relpath(os.path.join(basepath, key))
    if (os.path.exists(filepath) and
        # exclude library directories under client/
        not "dom/generated" in filepath and
        not "json/" in filepath):
      linenum = 0
      realcode = 0
      total_covered = 0
      escaped_lines = []
      file_summary = []
      with codecs.open(filepath, 'r', 'utf-8') as f:
        lines = f.read()
        for line in lines.split('\n'):
          linenum += 1
          stripline = line.strip()
          if linenum in result[key][0]:
            total_covered += 1
            file_summary.append("1")
            realcode += 1
          elif linenum in result[key][1]:
            file_summary.append("0")
            realcode += 1
          else:
            file_summary.append("2")

          escaped_lines.append(
              '"' + line.replace('"','\\"').replace('<', '<" + "') + '"')

      percent = total_covered * 100 / realcode

      # append a pair, the first component is only used for sorting
      print_summary_lines.append((filepath, "%s%3d%% (%4d of %4d) - %s%s"
           % (GREEN_COLOR if (percent >= GOOD_THRESHOLD) else
              YELLOW_COLOR if (percent >= OK_THRESHOLD) else
              RED_COLOR,
              percent, total_covered, realcode,
              filepath,
              NO_COLOR)))

      html_summary_lines.append(FILE_TEMPLATE % (
            filepath, filepath,
            filepath, ",".join(escaped_lines),
            filepath, ",".join(file_summary)))

  print_summary_lines.sort()
  print "\n".join([s for (percent, s) in print_summary_lines])

  outfile = os.path.join(outdir, 'coverage_summary.html')
  resource_dir = os.path.abspath(os.path.dirname(sys.argv[0]))

  # Inject css and js code within the coverage page:
  with open(os.path.join(resource_dir, 'coverage.css'), 'r') as f:
    style = f.read()
  with open(os.path.join(resource_dir, 'show_coverage.js'), 'r') as f:
    jscode = f.read()
  with codecs.open(outfile, 'w', 'utf-8') as f:
    f.write(SUMMARY_TEMPLATE % (style, jscode, "\n".join(html_summary_lines)))

  print ("Detailed summary available at: %s" % outfile)
  return 0

def ExecuteCommand(cmd, verbose):
  """Execute a command in a subprocess.
  """
  if verbose: print '\nExecuting: ' + ' '.join(cmd)
  pipe = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  (output, err) = pipe.communicate()
  if pipe.returncode != 0 and verbose:
    print 'Execution failed: ' + output + '\n' + err
    print output
    print err
  return pipe.returncode, output, err

def main():
  global total_tests
  parser = Flags()
  (options, args) = parser.parse_args()
  if not AreOptionsValid(options):
    parser.print_help()
    return 1

  # Create dir for instrumented code
  instrumented_dir = os.path.join(os.path.dirname(options.dir),
      os.path.basename(options.dir) + "_instrumented")

  # Determine the set of tests to execute
  prefix = options.tests_prefix
  tests = []
  if os.path.exists(prefix) and os.path.isdir(prefix):
    test_dir = prefix
    test_file_prefix = None
  else:
    test_dir = os.path.dirname(prefix)
    test_file_prefix = os.path.basename(prefix)

  for root, dirs, files in os.walk(test_dir):
    for f in files:
      if f.endswith('.app'):
        path = os.path.join(root, f)
        if test_file_prefix is None or path.startswith(prefix):
          tests.append(path)

  # Run tests and collect results
  result = dict()
  total_tests = len(tests)
  for test in tests:
    testname = test.replace("/", "_")
    script = testname + ".js"
    PrintNewTest(test)
    status = InstrumentScript(script, options.dir, instrumented_dir,
                              options.jscoverage, options.verbose)
    if status:
      print "skipped %s " % script
      global last_line_length
      last_line_length = 0
    else:
      sourcemapfile = os.path.join(
          os.path.join(options.sourcemapdir, test), test + ".js.map")
      CollectCoverageForTest(
          testname, options.controller, script, options.drt,
          options.dir, instrumented_dir, sourcemapfile, result, options.verbose)

  print "" # end compact progress indication
  ReportSummary(options.dir, result)
  return 0

# special functions and variables to print progress compactly
current_test = 0
current_test_name = ''
total_tests = 0 # to be filled in later after parsing options
last_line_length = 0

def PrintLine(s):
  global last_line_length
  if last_line_length > 0:
    print "\r" + (" " * last_line_length) + "\r",
  last_line_length = len(s)
  print s,
  sys.stdout.flush()

def PrintNewTest(test):
  global current_test
  global current_test_name
  global total_tests
  global GREEN_COLOR
  global NO_COLOR
  current_test += 1
  current_test_name = test
  PrintLine("%d of %d (%d%%): %s (%sstart%s)" % (current_test, total_tests,
      (100 * current_test / total_tests), test, GREEN_COLOR, NO_COLOR))

def PrintNewStep(message):
  global current_test
  global current_test_name
  global total_tests
  global GREEN_COLOR
  global NO_COLOR
  PrintLine("%d of %d (%d%%): %s (%s%s%s)" % (current_test, total_tests,
      (100 * current_test / total_tests), current_test_name,
      GREEN_COLOR, message, NO_COLOR))


def Flags():
  result = optparse.OptionParser()
  result.add_option("-d", "--dir",
      help="Directory where the compiled tests can be found.",
      default=None)
  result.add_option("--controller",
      help="Path to the coverage controller js file.",
      default=None)
  result.add_option("-v", "--verbose",
      help="Print a messages and progress",
      default=False,
      action="store_true")
  result.add_option("-t", "--tests_prefix",
      help="Prefix (typically a directory) where to crawl for test app files",
      type="string",
      action="store",
      default=None)
  result.add_option("--drt",
      help="The location for DumpRenderTree in the local file system",
      default=None)
  result.add_option("--jscoverage",
      help="The location for jscoverage in the local file system",
      default=None)
  result.add_option("--sourcemapdir",
      help="The location for sourcemap files in the local file system",
      default=None)
  result.set_usage(
      "coverage.py -d <cdart-output-dir> -t <test-dir> "
      "--drt=<path-to-DumpRenderTree> "
      "--jscoverage=<path-to-jscoverage> "
      "--sourcemapdir=<path-to-dir>"
      "[options]")
  return result

def AreOptionsValid(options):
  return (options.dir and options.tests_prefix and options.drt
          and options.jscoverage and options.sourcemapdir)

if __name__ == '__main__':
  sys.exit(main())
