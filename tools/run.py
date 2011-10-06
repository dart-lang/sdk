#!/usr/bin/env python
#
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#

"""
Runs a Dart unit test in different configurations: dartium, chromium, ia32, x64,
arm, simarm, and dartc. Example:

run.py --arch=dartium --mode=release --test=Test.dart
"""

import optparse
import os
from os.path import join, abspath, dirname, basename, relpath
import platform
import re
import shutil
import subprocess
import sys
import tempfile
import utils

OS_GUESS = utils.GuessOS()

HTML_CONTENTS = '''
<html>
<head>
  <title> Test %(title)s </title>
  <style>
     .unittest-table { font-family:monospace; border:1px; }
     .unittest-pass { background: #6b3;}
     .unittest-fail { background: #d55;}
     .unittest-error { background: #a11;}
  </style>
</head>
<body>
  <h1> Running %(title)s </h1>
  <script type="text/javascript" src="%(controller_script)s"></script>
  <script type="%(script_type)s" src="%(source_script)s"></script>
  <script type="text/javascript">
    // If 'startedDartTest' is not set, that means that the test did not have
    // a chance to load. This will happen when a load error occurs in the VM.
    // Give the machine time to start up.
    setTimeout(function() {
      if (window.layoutTestController
          && !window.layoutTestController.startedDartTest) {
        window.layoutTestController.notifyDone();
      }
    }, 3000);
  </script>
</body>
</html>
'''

DART_TEST_AS_LIBRARY = '''
#library('test');
#source('%(test)s');
'''

DART_CONTENTS = '''
#library('test');

#import('%(dom_library)s');
#import('%(test_framework)s');

#import('%(library)s', prefix: "Test");

pass() {
  document.body.innerHTML = 'PASS';
  window.postMessage('unittest-suite-done', '*');
}

fail(e, trace) {
  document.body.innerHTML = 'FAIL: $e, $trace';
  window.postMessage('unittest-suite-done', '*');
}

// All tests are registered as async tests on the UnitTestSuite.
// If the test uses the [:TestRunner:] we will a callback to wait for the
// done callback.
// Otherwise we will call [:testSuite.done():] immediately after the test
// finished.
main() {
  bool needsToWait = false;
  bool mainIsFinished = false;
  TestRunner.waitForDoneCallback = () { needsToWait = true; };
  TestRunner.doneCallback = () {
    if (mainIsFinished) {
      pass();
    } else {
      needsToWait = false;
    }
  };
  try {
    Test.main();
    if (!needsToWait) pass();
    mainIsFinished = true;
  } catch(var e, var trace) {
    fail(e, trace);
  }
}
'''


# Patterns for matching test options in .dart files.
VM_OPTIONS_PATTERN = re.compile(r"// VMOptions=(.*)")
DART_OPTIONS_PATTERN = re.compile(r"// DartOptions=(.*)")

# Pattern for checking if the test is a web test.
DOM_IMPORT_PATTERN = re.compile(r"^#import.*(dart:dom|html.dart)'\);",
                                re.MULTILINE)

# Pattern for matching the output of a browser test.
BROWSER_OUTPUT_PASS_PATTERN = re.compile(r"^Content-Type: text/plain\nPASS$",
                                         re.MULTILINE)

# Pattern for checking if the test is a library in itself.
LIBRARY_DEFINITION_PATTERN = re.compile(r"^#library\(.*\);",
                                        re.MULTILINE)
SOURCE_OR_IMPORT_PATTERN = re.compile(r"^#(source|import)\(.*\);",
                                      re.MULTILINE)


class Error(Exception):
  pass


def IsWebTest(test, source):
  return DOM_IMPORT_PATTERN.search(source)

def IsLibraryDefinition(test, source):
  if LIBRARY_DEFINITION_PATTERN.search(source): return True
  if SOURCE_OR_IMPORT_PATTERN.search(source):
    print ("WARNING for %s: Browser tests need a #library "
            "for a file that #import or #source" % test)
  return False


class Architecture(object):
  def __init__(self, root_path, arch, mode, test):
    self.root_path = root_path;
    self.arch = arch;
    self.mode = mode;
    self.test = test;
    self.build_root = utils.GetBuildRoot(OS_GUESS, self.mode, self.arch)
    source = file(test).read()
    self.vm_options = utils.ParseTestOptions(VM_OPTIONS_PATTERN,
                                             source,
                                             root_path)
    if not self.vm_options: self.vm_options = []

    self.dart_options = utils.ParseTestOptions(DART_OPTIONS_PATTERN,
                                               source,
                                               root_path)
    self.is_web_test = IsWebTest(test, source)
    self.temp_dir = None

  def HasFatalTypeErrors(self):
    return False

  def GetTestFrameworkPath(self):
    return join(self.root_path, 'tests', 'isolate', 'src',
               'TestFramework.dart')

class BrowserArchitecture(Architecture):
  def __init__(self, root_path, arch, mode, test):
    super(BrowserArchitecture, self).__init__(root_path, arch, mode, test)
    self.temp_dir = tempfile.mkdtemp();
    if not self.is_web_test: self.GenerateWebTestScript()

  def GetTestScriptFile(self):
    """Returns the name of the .dart file to compile."""
    if self.is_web_test: return abspath(self.test)
    return join(self.temp_dir, 'test.dart')

  def GetHtmlContents(self):
    script_type = self.GetScriptType()

    controller_path = join(self.root_path,
        'client', 'testing', 'unittest', 'test_controller.js')

    return HTML_CONTENTS % { 'title'            : self.test,
                             'controller_script': controller_path,
                             'script_type'      : script_type,
                             'source_script'    : self.GetScriptPath() }

  def GetHtmlPath(self):
    # Resources for web tests are relative to the 'html' file. We
    # output the 'html' file in the 'out' directory instead of the temporary
    # directory because we can easily go the the resources in 'client' through
    # 'out'.
    if self.is_web_test:
      html_path = join(self.root_path, 'client', self.build_root)
      if not os.path.exists(html_path): os.makedirs(html_path)
      return html_path

    return self.temp_dir

  def GetTestContents(self, library_file):
    unittest_path = join(self.root_path,
                         'client', 'testing', 'unittest', 'unittest.dart')
    if self.arch == 'chromium':
      dom_path = join(self.root_path,
                      'client', 'testing', 'unittest', 'dom_for_unittest.dart')
    else:
      dom_path = join('dart:dom')

    test_framework_path = self.GetTestFrameworkPath()
    test_name = basename(self.test)
    test_path = abspath(self.test)

    inputs = { 'unittest': unittest_path,
               'test': test_path,
               'dom_library': dom_path,
               'test_framework': test_framework_path,
               'library': library_file }
    return DART_CONTENTS % inputs

  def GenerateWebTestScript(self):
    if IsLibraryDefinition(self.test, file(self.test).read()):
      library_file = abspath(self.test)
    else:
      library_file = 'test_as_library.dart'
      test_as_library = DART_TEST_AS_LIBRARY % { 'test': abspath(self.test) }
      test_as_library_file = join(self.temp_dir, library_file)
      f = open(test_as_library_file, 'w')
      f.write(test_as_library)
      f.close()

    app_output_file = self.GetTestScriptFile()
    f = open(app_output_file, 'w')
    f.write(self.GetTestContents(library_file))
    f.close()

  def GetRunCommand(self, fatal_static_type_errors = False):
    # For some reason, DRT needs to be called via an absolute path
    drt_location = join(self.root_path,
        'client', 'tests', 'drt', 'DumpRenderTree')

    # On Mac DumpRenderTree is a .app folder
    if platform.system() == 'Darwin':
      drt_location += '.app/Contents/MacOS/DumpRenderTree'

    drt_flags = [ '--no-timeout' ]
    dart_flags = '--dart-flags=--enable_asserts --enable_type_checks '
    dart_flags += ' '.join(self.vm_options)

    if self.arch == 'chromium' and self.mode == 'release':
      dart_flags += ' --optimize '
    drt_flags.append(dart_flags)

    html_output_file = join(self.GetHtmlPath(), self.GetHtmlName())
    f = open(html_output_file, 'w')
    f.write(self.GetHtmlContents())
    f.close()

    drt_flags.append(html_output_file)

    return [drt_location] + drt_flags

  def HasFailed(self, output):
    return not BROWSER_OUTPUT_PASS_PATTERN.search(output)

  def RunTest(self, verbose):
    retcode = self.Compile()
    if retcode != 0: return 1

    command = self.GetRunCommand()

    status, output, err = ExecutePipedCommand(command, verbose)
    if not self.HasFailed(output):
      self.Cleanup()
      return 0

    # TODO(sigmund): print better error message, including how to run test
    # locally, and translate error traces using source map info.
    print "(FAIL) test page:\033[31m " + command[2] + " \033[0m"
    if verbose:
      print 'Additional info: '
      print output
      print err
    return 1

  def Cleanup(self):
    if self.temp_dir:
      shutil.rmtree(self.temp_dir)
      self.temp_dir = None


class ChromiumArchitecture(BrowserArchitecture):
  def __init__(self, root_path, arch, mode, test):
    super(ChromiumArchitecture, self).__init__(root_path, arch, mode, test)

  def GetScriptType(self):
    return 'text/javascript'

  def GetScriptPath(self):
    """ Returns the name of the output .js file to create """
    path = self.GetTestScriptFile()
    return abspath(os.path.join(self.temp_dir,
                                os.path.basename(path) + '.js'))


  def GetHtmlName(self):
    return relpath(self.test, self.root_path).replace(os.sep, '_') + '.html'

  def GetCompileCommand(self, fatal_static_type_errors=False):
    """ Returns cmdline as an array to invoke the compiler on this test"""
    # We need an absolute path because the compilation will run
    # in a temporary directory.

    dartc = abspath(join(utils.GetBuildRoot(OS_GUESS, self.mode, 'dartc'),
                         'compiler',
                         'bin',
                         'dartc'))
    if utils.IsWindows(): dartc += '.exe'
    cmd = [dartc, '--work', self.temp_dir]
    cmd += self.vm_options
    cmd += ['--out', self.GetScriptPath()]
    if fatal_static_type_errors:
      cmd.append('-fatal-type-errors')
    cmd.append(self.GetTestScriptFile())
    return cmd

  def Compile(self):
    return ExecuteCommand(self.GetCompileCommand())


class DartiumArchitecture(BrowserArchitecture):
  def __init__(self, root_path, arch, mode, test):
    super(DartiumArchitecture, self).__init__(root_path, arch, mode, test)

  def GetScriptType(self):
    return 'application/dart'

  def GetScriptPath(self):
    return 'file:///' + self.GetTestScriptFile()

  def GetHtmlName(self):
    path = relpath(self.test, self.root_path).replace(os.sep, '_')
    return path + '.dartium.html'

  def GetCompileCommand(self, fatal_static_type_errors=False):
    return None

  def Compile(self):
    return 0


class StandaloneArchitecture(Architecture):
  def __init__(self, root_path, arch, mode, test):
    super(StandaloneArchitecture, self).__init__(root_path, arch, mode, test)

  def GetCompileCommand(self, fatal_static_type_errors=False):
    return None

  def GetRunCommand(self, fatal_static_type_errors=False):
    dart = self.GetExecutable()
    test_name = basename(self.test)
    test_path = abspath(self.test)
    command = [dart] + self.vm_options
    (classname, extension) = os.path.splitext(test_name)
    if self.dart_options:
      command += self.dart_options
    elif (extension == '.dart'):
      if fatal_static_type_errors:
        command += self.GetFatalTypeErrorsFlags()
      if '_' in classname:
        (classname, sep, tag) = classname.rpartition('_')
      command += [test_path]
    else:
      command += ['--', test_path]

    return command

  def GetFatalTypeErrorsFlags(self):
    return []

  def RunTest(self, verbose):
    command = self.GetRunCommand()
    return ExecuteCommand(command, verbose)

  def Cleanup(self):
    return


# Long term, we should do the running machinery that is currently in
# DartRunner.java
class DartcArchitecture(StandaloneArchitecture):
  def __init__(self, root_path, arch, mode, test):
    super(DartcArchitecture, self).__init__(root_path, arch, mode, test)

  def GetExecutable(self):
    return abspath(join(self.build_root, 'compiler', 'bin', 'dartc_test'))

  def GetFatalTypeErrorsFlags(self):
    return ['--fatal-type-errors']

  def HasFatalTypeErrors(self):
    return True

  def GetRunCommand(self, fatal_static_type_errors=False):
    cmd = super(DartcArchitecture, self).GetRunCommand(
        fatal_static_type_errors)
    return cmd


class RuntimeArchitecture(StandaloneArchitecture):
  def __init__(self, root_path, arch, mode, test):
    super(RuntimeArchitecture, self).__init__(root_path, arch, mode, test)

  def GetExecutable(self):
    return abspath(join(self.build_root, 'dart_bin'))


def ExecutePipedCommand(cmd, verbose):
  """Execute a command in a subprocess.
  """
  if verbose: print 'Executing: ' + ' '.join(cmd)
  pipe = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  (output, err) = pipe.communicate()
  if pipe.returncode != 0 and verbose:
    print 'Execution failed: ' + output + '\n' + err
    print output
    print err
  return pipe.returncode, output, err


def ExecuteCommand(cmd, verbose = False):
  """Execute a command in a subprocess.
  """
  if verbose: print 'Executing: ' + ' '.join(cmd)
  return subprocess.call(cmd)


def AreOptionsValid(options):
  if not options.arch in ['ia32', 'x64', 'arm', 'simarm', 'dartc', 'dartium',
                          'chromium']:
    print 'Unknown arch %s' % options.arch
    return None

  return options.test


def Flags():
  result = optparse.OptionParser()
  result.add_option("-v", "--verbose",
      help="Print messages",
      default=False,
      action="store_true")
  result.add_option("-t", "--test",
      help="App or Dart file containing the test",
      type="string",
      action="store",
      default=None)
  result.add_option("--arch",
      help="The architecture to run tests for",
      metavar="[ia32,x64,arm,simarm,dartc,chromium,dartium]",
      default=utils.GuessArchitecture())
  result.add_option("-m", "--mode",
      help="The test modes in which to run",
      metavar='[debug,release]',
      default='debug')
  result.set_usage("run.py --arch ARCH --mode MODE -t TEST")
  return result


def GetArchitecture(arch, mode, test):
  root_path = abspath(join(dirname(sys.argv[0]), '..'))
  if arch == 'chromium':
    return ChromiumArchitecture(root_path, arch, mode, test)

  elif arch == 'dartium':
    return DartiumArchitecture(root_path, arch, mode, test)

  elif arch in ['ia32', 'x64', 'simarm', 'arm']:
    return RuntimeArchitecture(root_path, arch, mode, test)

  elif arch == 'dartc':
    return DartcArchitecture(root_path, arch, mode, test)


def Main():
  parser = Flags()
  (options, args) = parser.parse_args()
  if not AreOptionsValid(options):
    parser.print_help()
    return 1

  return GetArchitecture(options.arch, options.mode,
                         options.test).RunTest(options.verbose)


if __name__ == '__main__':
  sys.exit(Main())
