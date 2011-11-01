# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
#

import os
import platform
import re
import shutil
import subprocess
import sys
import tempfile

import utils

OS_GUESS = utils.GuessOS()

HTML_CONTENTS = """
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
    // If nobody intercepts the error, finish the test.
    window.onerror = function() { window.layoutTestController.notifyDone() };

    window.addEventListener('DOMContentLoaded', function() {
      // If 'startedDartTest' is not set, that means that the test did not have
      // a chance to load. This will happen when a load error occurs in the VM.
      // Give the machine time to start up.
      setTimeout(function() {
        // A window.postMessage might have been enqueued after this timeout.
        // Just sleep another time to give the browser the time to process the
        // posted message.
        setTimeout(function() {
          if (window.layoutTestController
              && !window.layoutTestController.startedDartTest) {
            window.layoutTestController.notifyDone();
          }
        }, 0);
      }, 50);
    }, false);
  </script>
</body>
</html>
"""

DART_TEST_AS_LIBRARY = """
#library('test');
#source('%(test)s');
"""

DART_CONTENTS = """
#library('test');

#import('%(dom_library)s');
#import('%(test_framework)s');

#import('%(library)s', prefix: "Test");

waitForDone() {
  window.postMessage('unittest-suite-wait-for-done', '*');
}

pass() {
  document.body.innerHTML = 'PASS';
  window.postMessage('unittest-suite-done', '*');
}

fail(e, trace) {
  document.body.innerHTML = 'FAIL: $e, $trace';
  window.postMessage('unittest-suite-done', '*');
}

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
    if (needsToWait) {
      waitForDone();
    } else {
      pass();
    }
    mainIsFinished = true;
  } catch(var e, var trace) {
    fail(e, trace);
  }
}
"""


# Patterns for matching test options in .dart files.
DART_OPTIONS_PATTERN = re.compile(r'// DartOptions=(.*)')

# Pattern for checking if the test is a web test.
DOM_IMPORT_PATTERN = re.compile(r'#import.*(dart:(dom|html)|html\.dart).*\);',
                                re.MULTILINE)

# Pattern for matching the output of a browser test.
BROWSER_OUTPUT_PASS_PATTERN = re.compile(r'^Content-Type: text/plain\nPASS$',
                                         re.MULTILINE)

# Pattern for checking if the test is a library in itself.
LIBRARY_DEFINITION_PATTERN = re.compile(r'^#library\(.*\);',
                                        re.MULTILINE)
SOURCE_OR_IMPORT_PATTERN = re.compile(r'^#(source|import)\(.*\);',
                                      re.MULTILINE)


class Error(Exception):
  """Base class for exceptions in this module."""
  pass


def _IsWebTest(source):
  """Returns True if the source includes a dart dom library #import."""
  return DOM_IMPORT_PATTERN.search(source)


def IsLibraryDefinition(test, source):
  """Returns True if the source has a #library statement."""
  if LIBRARY_DEFINITION_PATTERN.search(source):
    return True
  if SOURCE_OR_IMPORT_PATTERN.search(source):
    print ('WARNING for %s: Browser tests need a #library '
           'for a file that #import or #source' % test)
  return False


class Architecture(object):
  """Definitions for different ways to test based on the component flag."""

  def __init__(self, root_path, arch, mode, component, test):
    self.root_path = root_path
    self.arch = arch
    self.mode = mode
    self.component = component
    self.test = test
    self.build_root = utils.GetBuildRoot(OS_GUESS, self.mode, self.arch)
    source = file(test).read()
    self.vm_options = []
    self.dart_options = utils.ParseTestOptions(DART_OPTIONS_PATTERN,
                                               source,
                                               root_path)
    self.is_web_test = _IsWebTest(source)
    self.temp_dir = None

  def HasFatalTypeErrors(self):
    """Returns True if this type of component supports --fatal-type-errors."""
    return False

  def GetTestFrameworkPath(self):
    """Path to dart source (TestFramework.dart) for testing framework."""
    return os.path.join(self.root_path, 'tests', 'isolate', 'src',
                        'TestFramework.dart')


class BrowserArchitecture(Architecture):
  """Architecture that runs compiled dart->JS through a browser."""

  def __init__(self, root_path, arch, mode, component, test):
    super(BrowserArchitecture, self).__init__(root_path, arch, mode, component,
                                              test)
    self.temp_dir = tempfile.mkdtemp()
    if not self.is_web_test: self.GenerateWebTestScript()

  def GetTestScriptFile(self):
    """Returns the name of the .dart file to compile."""
    if self.is_web_test: return os.path.abspath(self.test)
    return os.path.join(self.temp_dir, 'test.dart')

  def GetHtmlContents(self):
    """Fills in the HTML_CONTENTS template with info for this architecture."""
    script_type = self.GetScriptType()
    controller_path = os.path.join(self.root_path, 'client', 'testing',
                                   'unittest', 'test_controller.js')
    return HTML_CONTENTS % {
        'title': self.test,
        'controller_script': controller_path,
        'script_type': script_type,
        'source_script': self.GetScriptPath()
    }

  def GetHtmlPath(self):
    """Creates a path for the generated .html file.

    Resources for web tests are relative to the 'html' file. We
    output the 'html' file in the 'out' directory instead of the temporary
    directory because we can easily go the the resources in 'client' through
    'out'.

    Returns:
      Created path for the generated .html file.
    """
    if self.is_web_test:
      html_path = os.path.join(self.root_path, 'client', self.build_root)
      if not os.path.exists(html_path):
        os.makedirs(html_path)
      return html_path

    return self.temp_dir

  def GetTestContents(self, library_file):
    """Pastes a preamble on the front of the .dart file before testing."""
    unittest_path = os.path.join(self.root_path, 'client', 'testing',
                                 'unittest', 'unittest.dart')

    if self.component == 'chromium':
      dom_path = os.path.join(self.root_path, 'client', 'testing',
                              'unittest', 'dom_for_unittest.dart')
    else:
      dom_path = os.path.join('dart:dom')

    test_framework_path = self.GetTestFrameworkPath()
    test_path = os.path.abspath(self.test)

    inputs = {
        'unittest': unittest_path,
        'test': test_path,
        'dom_library': dom_path,
        'test_framework': test_framework_path,
        'library': library_file
    }
    return DART_CONTENTS % inputs

  def GenerateWebTestScript(self):
    """Creates a .dart file to run in the test."""
    if IsLibraryDefinition(self.test, file(self.test).read()):
      library_file = os.path.abspath(self.test)
    else:
      library_file = 'test_as_library.dart'
      test_as_library = DART_TEST_AS_LIBRARY % {
          'test': os.path.abspath(self.test)
      }
      test_as_library_file = os.path.join(self.temp_dir, library_file)
      f = open(test_as_library_file, 'w')
      f.write(test_as_library)
      f.close()

    app_output_file = self.GetTestScriptFile()
    f = open(app_output_file, 'w')
    f.write(self.GetTestContents(library_file))
    f.close()

  def GetRunCommand(self, fatal_static_type_errors=False):
    """Returns a command line to execute for the test."""
    fatal_static_type_errors = fatal_static_type_errors  # shutup lint!
    # For some reason, DRT needs to be called via an absolute path
    drt_location = os.path.join(self.root_path, 'client', 'tests', 'drt',
                                'DumpRenderTree')

    # On Mac DumpRenderTree is a .app folder
    if platform.system() == 'Darwin':
      drt_location += '.app/Contents/MacOS/DumpRenderTree'

    drt_flags = ['--no-timeout']
    dart_flags = '--dart-flags=--enable_asserts --enable_type_checks '
    dart_flags += ' '.join(self.vm_options)

    drt_flags.append(dart_flags)

    html_output_file = os.path.join(self.GetHtmlPath(), self.GetHtmlName())
    f = open(html_output_file, 'w')
    f.write(self.GetHtmlContents())
    f.close()

    drt_flags.append(html_output_file)

    return [drt_location] + drt_flags

  def HasFailed(self, output):
    """Return True if the 'PASS' result string isn't in the output."""
    return not BROWSER_OUTPUT_PASS_PATTERN.search(output)

  def RunTest(self, verbose):
    """Calls GetRunCommand() and executes the returned commandline.

    Args:
      verbose: if True, print additional diagnostics to stdout.

    Returns:
      Return code from executable. 0 == PASS, 253 = CRASH, anything
      else is treated as FAIL
    """
    retcode = self.Compile()
    if retcode != 0: return 1

    command = self.GetRunCommand()

    unused_status, output, err = ExecutePipedCommand(command, verbose)
    if not self.HasFailed(output):
      return 0

    # TODO(sigmund): print better error message, including how to run test
    # locally, and translate error traces using source map info.
    print '(FAIL) test page:\033[31m %s \033[0m' % command[2]
    if verbose:
      print 'Additional info: '
      print output
      print err
    return 1

  def Cleanup(self):
    """Removes temporary files created for the test."""
    if self.temp_dir:
      shutil.rmtree(self.temp_dir)
      self.temp_dir = None


class ChromiumArchitecture(BrowserArchitecture):
  """Architecture that runs compiled dart->JS through a chromium DRT."""

  def __init__(self, root_path, arch, mode, component, test):
    super(ChromiumArchitecture, self).__init__(root_path, arch, mode, component, test)

  def GetScriptType(self):
    return 'text/javascript'

  def GetScriptPath(self):
    """Returns the name of the output .js file to create."""
    path = self.GetTestScriptFile()
    return os.path.abspath(os.path.join(self.temp_dir,
                                        os.path.basename(path) + '.js'))

  def GetHtmlName(self):
    """Returns the name of the output .html file to create."""
    relpath = os.path.relpath(self.test, self.root_path)
    return relpath.replace(os.sep, '_') + '.html'

  def GetCompileCommand(self, fatal_static_type_errors=False):
    """Returns cmdline as an array to invoke the compiler on this test."""

    # We need an absolute path because the compilation will run
    # in a temporary directory.
    build_root = utils.GetBuildRoot(OS_GUESS, self.mode, 'dartc')
    dartc = os.path.abspath(os.path.join(build_root, 'compiler', 'bin',
                                         'dartc'))
    if utils.IsWindows(): dartc += '.exe'
    cmd = [dartc, '--work', self.temp_dir]
    if self.mode == 'release':
      cmd += ['--optimize']
    cmd += self.vm_options
    cmd += ['--out', self.GetScriptPath()]
    if fatal_static_type_errors:
      # TODO(zundel): update to --fatal_type_errors for both VM and Compiler
      cmd.append('-fatal-type-errors')
    cmd.append(self.GetTestScriptFile())
    return cmd

  def Compile(self):
    return ExecuteCommand(self.GetCompileCommand())


class DartiumArchitecture(BrowserArchitecture):
  """Architecture that runs dart in an VM embedded in DumpRenderTree."""

  def __init__(self, root_path, arch, mode, component, test):
    super(DartiumArchitecture, self).__init__(root_path, arch, mode, component, test)

  def GetScriptType(self):
    return 'application/dart'

  def GetScriptPath(self):
    return 'file:///' + self.GetTestScriptFile()

  def GetHtmlName(self):
    path = os.path.relpath(self.test, self.root_path).replace(os.sep, '_')
    return path + '.dartium.html'

  def GetCompileCommand(self, fatal_static_type_errors=False):
    fatal_static_type_errors = fatal_static_type_errors  # shutup lint!
    return None

  def Compile(self):
    return 0


class StandaloneArchitecture(Architecture):
  """Base class for architectures that run tests without a browser."""

  def __init__(self, root_path, arch, mode, component, test):
    super(StandaloneArchitecture, self).__init__(root_path, arch, mode, component,
                                                 test)

  def GetCompileCommand(self, fatal_static_type_errors=False):
    fatal_static_type_errors = fatal_static_type_errors  # shutup lint!
    return None

  def GetRunCommand(self, fatal_static_type_errors=False):
    """Returns a command line to execute for the test."""
    dart = self.GetExecutable()
    test_name = os.path.basename(self.test)
    test_path = os.path.abspath(self.test)
    command = [dart] + self.vm_options
    if self.mode == 'release':
      command += ['--optimize']
    (classname, extension) = os.path.splitext(test_name)
    if self.dart_options:
      command += self.dart_options
    elif extension == '.dart':
      if fatal_static_type_errors:
        command += self.GetFatalTypeErrorsFlags()
      if '_' in classname:
        (classname, unused_sep, unused_tag) = classname.rpartition('_')
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
  """Runs the Dart ->JS compiler then runs the result in a standalone JS VM."""

  def __init__(self, root_path, arch, mode, component, test):
    super(DartcArchitecture, self).__init__(root_path, arch, mode, component, test)

  def GetExecutable(self):
    """Returns the name of the executable to run the test."""
    return os.path.abspath(os.path.join(self.build_root,
                                        'compiler',
                                        'bin',
                                        'dartc_test'))

  def GetFatalTypeErrorsFlags(self):
    return ['--fatal-type-errors']

  def HasFatalTypeErrors(self):
    return True

  def GetRunCommand(self, fatal_static_type_errors=False):
    """Returns a command line to execute for the test."""
    cmd = super(DartcArchitecture, self).GetRunCommand(
        fatal_static_type_errors)
    return cmd


class RuntimeArchitecture(StandaloneArchitecture):
  """Executes tests on the standalone VM (runtime)."""

  def __init__(self, root_path, arch, mode, component, test):
    super(RuntimeArchitecture, self).__init__(root_path, arch, mode, component,
                                              test)

  def GetExecutable(self):
    """Returns the name of the executable to run the test."""
    return os.path.abspath(os.path.join(self.build_root, 'dart_bin'))


def ExecutePipedCommand(cmd, verbose):
  """Execute a command in a subprocess."""
  if verbose:
    print 'Executing: ' + ' '.join(cmd)
  pipe = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  (output, err) = pipe.communicate()
  if pipe.returncode != 0 and verbose:
    print 'Execution failed: ' + output + '\n' + err
    print output
    print err
  return pipe.returncode, output, err


def ExecuteCommand(cmd, verbose=False):
  """Execute a command in a subprocess."""
  if verbose: print 'Executing: ' + ' '.join(cmd)
  return subprocess.call(cmd)


def GetArchitecture(arch, mode, component, test):
  root_path = os.path.abspath(os.path.join(os.path.dirname(sys.argv[0]), '..'))
  if component == 'chromium':
    return ChromiumArchitecture(root_path, arch, mode, component, test)

  elif component == 'dartium':
    return DartiumArchitecture(root_path, arch, mode, component, test)

  elif component == 'vm':
    return RuntimeArchitecture(root_path, arch, mode, component, test)

  elif component == 'dartc':
    return DartcArchitecture(root_path, arch, mode, component, test)
