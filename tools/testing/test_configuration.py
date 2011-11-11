# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""Common Testconfiguration subclasses used to define a class of tests."""

import atexit
import fileinput
import os
import re
import shutil


import test
from testing import test_case
import utils


# Patterns for matching test options in .dart files.
VM_OPTIONS_PATTERN = re.compile(r"// VMOptions=(.*)")

class Error(Exception):
  pass


class TestConfigurationError(Error):
  pass


class StandardTestConfiguration(test.TestConfiguration):
  """Configuration that looks for .dart files in the tests/*/src dirs."""
  LEGAL_KINDS = set(['compile-time error',
                     'runtime error',
                     'static type error',
                     'dynamic type error'])

  def __init__(self, context, root, flags = []):
    super(StandardTestConfiguration, self).__init__(context, root, flags)

  def _Cleanup(self, tests):
    """Remove any temporary files created by running the test."""
    if self.context.keep_temporary_files:
      return

    dirs = []
    for t in tests:
      if t.run_arch:
        temp_dir = t.run_arch.temp_dir
        if temp_dir:
          dirs.append(temp_dir)
    if not dirs:
      return
    if not utils.Daemonize():
      return
    os.execlp('rm', *(['rm', '-rf'] + dirs))

  def CreateTestCases(self, test_path, path, filename, mode, arch, component):
    """Given a .dart filename, create a StandardTestCase from it."""
    # Look for VM specified as comments in the source file. If
    # several sets of VM options are specified create a separate
    # test for each set.
    source = file(filename).read()
    vm_options_list = utils.ParseTestOptionsMultiple(VM_OPTIONS_PATTERN,
                                                     source,
                                                     test_path)
    tags = {}
    if filename.endswith('.dart'):
      tags = self.SplitMultiTest(test_path, filename)
    if component in ['dartium', 'chromium', 'webdriver']:
      if tags:
        return []
      else:
        if vm_options_list:
          tests = []
          for options in vm_options_list:
            tests.append(test_case.BrowserTestCase(
                self.context, test_path, filename, False, mode, arch, component,
                options + self.flags))
          return tests
        else:
          return [test_case.BrowserTestCase(
              self.context, test_path, filename, False, mode, arch, component,
              self.flags)]
    else:
      tests = []
      if tags:
        for tag in sorted(tags):
          kind, test_source = tags[tag]
          if not self.Contains(path, test_path + [tag]):
            continue
          tests.append(test_case.MultiTestCase(self.context,
                                               test_path + [tag],
                                               test_source,
                                               kind,
                                               mode, arch, component,
                                               self.flags))
      else:
        if vm_options_list:
          for options in vm_options_list:
            tests.append(test_case.StandardTestCase(self.context,
                test_path, filename, mode, arch, component,
                options + self.flags))
        else:
          tests.append(test_case.StandardTestCase(self.context,
              test_path, filename, mode, arch, component, self.flags))
      return tests

  def ListTests(self, current_path, path, mode, arch, component):
    """Searches for *Test.dart files and returns list of TestCases."""
    tests = []
    for root, unused_dirs, files in os.walk(os.path.join(self.root, 'src')):
      for f in [x for x in files if self.IsTest(x)]:
        if f.endswith('.dart'):
          test_path = current_path + [f[:-5]]  # Remove .dart suffix.
        elif f.endswith('.app'):
          # TODO(zundel): .app files are used only the dromaeo test
          # and should be removed.
          test_path = current_path + [f[:-4]]  # Remove .app suffix.
        if not self.Contains(path, test_path):
          continue
        tests.extend(self.CreateTestCases(test_path, path,
                                          os.path.join(root, f),
                                          mode, arch, component))
    atexit.register(lambda: self._Cleanup(tests))
    return tests

  def IsTest(self, name):
    """Returns True if the file name is a test file."""
    return name.endswith('Test.dart') or name.endswith('Test.app')

  def GetTestStatus(self, sections, defs):
    """Reads the .status file of the TestSuite."""
    status = os.path.join(self.root, os.path.basename(self.root) + '.status')
    if os.path.exists(status):
      test.ReadConfigurationInto(status, sections, defs)

  def FindReferencedFiles(self, lines):
    """Scours the lines containing source code for include directives."""
    referenced_files = []
    for line in lines:
      m = re.match("#(source|import)\(['\"](.*)['\"]\);", line)
      if m:
        file_name = m.group(2)
        if not file_name.startswith('dart:'):
          referenced_files.append(file_name)
    return referenced_files

  def SplitMultiTest(self, test_path, filename):
    """Takes a file with multiple test case defined.

    Splits the file into multiple TestCase instances.

    Args:
      test_path: temporary dir to write split test case data.
      filename: name of the file to split.

    Returns:
      sequence of test cases split from file.

    Raises:
      TestConfigurationError: when a problem with the multi-test-case
          syntax is encountered.
    """
    (name, extension) = os.path.splitext(os.path.basename(filename))
    with open(filename, 'r') as s:
      source = s.read()
    lines = source.splitlines()
    tags = {}
    for line in lines:
      (unused_code, sep, info) = line.partition(' /// ')
      if sep:
        (tag, sep, kind) = info.partition(': ')
        if tag in tags:
          if kind != 'continued':
            raise TestConfigurationError('duplicated tag %s' % tag)
        elif kind not in StandardTestConfiguration.LEGAL_KINDS:
          raise TestConfigurationError('unrecognized kind %s' % kind)
        else:
          tags[tag] = kind
    if not tags:
      return {}
    # Prepare directory for generated tests.
    tests = {}
    generated_test_dir = os.path.join(self.context.workspace, 'generated_tests')
    generated_test_dir = os.path.join(generated_test_dir, *test_path[:-1])
    if not os.path.exists(generated_test_dir):
      os.makedirs(generated_test_dir)
    # Copy referenced files to generated tests directory.
    referenced_files = self.FindReferencedFiles(lines)
    for referenced_file in referenced_files:
      shutil.copy(os.path.join(os.path.dirname(filename), referenced_file),
                  os.path.join(generated_test_dir, referenced_file))
    # Generate test for each tag found in the main test file.
    for tag in tags:
      test_lines = []
      for line in lines:
        if ' /// ' in line:
          if ' /// %s:' % tag in line:
            test_lines.append(line)
          else:
            test_lines.append('// %s' % line)
        else:
          test_lines.append(line)
      test_filename = os.path.join(generated_test_dir,
                                   '%s_%s%s' % (name, tag, extension))
      with open(test_filename, 'w') as test_file:
        for line in test_lines:
          print >> test_file, line
      tests[tag] = (tags[tag], test_filename)
    test_filename = os.path.join(generated_test_dir,
                                 '%s%s' % (name, extension))
    with open(test_filename, 'w') as test_file:
      for line in lines:
        if ' /// ' not in line:
          print >> test_file, line
        else:
          print >> test_file, '//', line
    tests['none'] = ('', test_filename)
    return tests


class BrowserTestConfiguration(StandardTestConfiguration):
  """A configuration used to run tests inside a browser."""

  def __init__(self, context, root, fatal_static_type_errors=False):
    super(BrowserTestConfiguration, self).__init__(context, root)
    self.fatal_static_type_errors = fatal_static_type_errors

  def ListTests(self, current_path, path, mode, arch, component):
    """Searches for *Test .dart files and returns list of TestCases."""
    tests = []
    for root, unused_dirs, files in os.walk(self.root):
      for f in [x for x in files if self.IsTest(x)]:
        relative = os.path.relpath(root, self.root).split(os.path.sep)
        test_path = current_path + relative + [os.path.splitext(f)[0]]
        if not self.Contains(path, test_path):
          continue
        tests.append(test_case.BrowserTestCase(self.context,
                                               test_path,
                                               os.path.join(root, f),
                                               self.fatal_static_type_errors,
                                               mode, arch, component))
    atexit.register(lambda: self._Cleanup(tests))
    return tests

  def IsTest(self, name):
    return name.endswith('_tests.dart')


class CompilationTestConfiguration(test.TestConfiguration):
  """Configuration that searches specific directories for apps to compile.

  Expects a status file named  dartc.status
  """

  def __init__(self, context, root):
    super(CompilationTestConfiguration, self).__init__(context, root)

  def ListTests(self, current_path, path, mode, arch, component):
    """Searches for *Test.dart files and returns list of TestCases."""
    tests = []
    client_path = os.path.normpath(os.path.join(self.root, '..', '..'))

    for src_dir in self.SourceDirs():
      for root, dirs, files in os.walk(os.path.join(client_path, src_dir)):
        ignore_dirs = [d for d in dirs if d.startswith('.')]
        for d in ignore_dirs:
          dirs.remove(d)
        for f in files:
          filename = [os.path.basename(client_path)]
          filename.extend(root[len(client_path) + 1:].split(os.path.sep))
          filename.append(f)  # Remove .lib or .app suffix.
          test_path = current_path + filename
          test_dart_file = os.path.join(root, f)
          if (not self.Contains(path, test_path)
              or not self.IsTest(test_dart_file)):
            continue
          tests.append(test_case.CompilationTestCase(test_path,
                                                     self.context,
                                                     test_dart_file,
                                                     mode,
                                                     arch,
                                                     component))
    atexit.register(lambda: self._Cleanup(tests))
    return tests

  def SourceDirs(self):
    """Returns a list of directories to scan for files to compile."""
    raise TestConfigurationError(
        'Subclasses must implement SourceDirs()')

  def IsTest(self, name):
    """Returns True if name is a test case to be compiled."""
    if not name.endswith('.dart'):
      return False
    if os.path.exists(name):
      # TODO(dgrove): can we end reading the input early?
      for line in fileinput.input(name):
        if re.match('#', line):
          fileinput.close()
          return True
      fileinput.close()
      return False
    return False

  def GetTestStatus(self, sections, defs):
    status = os.path.join(self.root, 'dartc.status')
    if os.path.exists(status):
      test.ReadConfigurationInto(status, sections, defs)

  def _Cleanup(self, tests):
    if not utils.Daemonize(): return
    os.execlp('rm', *(['rm', '-rf'] + [t.temp_dir for t in tests]))
    raise
