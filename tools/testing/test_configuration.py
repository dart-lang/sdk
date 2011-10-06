# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import atexit
import fileinput
import os
import test
import platform
import re
import run
import shutil
import sys
import tempfile

from testing import test_case
import test
import utils

from os.path import join, exists, basename

import utils

class Error(Exception):
  pass

class TestConfigurationError(Error):
  pass

class StandardTestConfiguration(test.TestConfiguration):
  LEGAL_KINDS = set(['compile-time error',
                     'runtime error',
                     'static type error',
                     'dynamic type error'])

  def __init__(self, context, root):
    super(StandardTestConfiguration, self).__init__(context, root)

  def _cleanup(self, tests):
    if self.context.keep_temporary_files: return

    dirs = []
    for t in tests:
      if t.run_arch != None:
        temp_dir = t.run_arch.temp_dir
        if temp_dir != None: dirs.append(temp_dir)

    if len(dirs) == 0: return
    if not utils.Daemonize(): return

    os.execlp('rm', *(['rm', '-rf'] + dirs))


  def CreateTestCases(self, test_path, path, filename, mode, arch):
    tags = {}
    if filename.endswith(".dart"):
      tags = self.SplitMultiTest(test_path, filename)
    if arch in ['dartium', 'chromium']:
      if tags:
        return []
      else:
        return [test_case.BrowserTestCase(
            self.context, test_path, filename, False, mode, arch)]
    else:
      tests = []
      if tags:
        for tag in sorted(tags):
          kind, test_source = tags[tag]
          if not self.Contains(path, test_path + [tag]):
            continue
          tests.append(test_case.MultiTestCase(self.context,
              test_path + [tag], test_source, kind, mode, arch))
      else:
        tests.append(test_case.StandardTestCase(self.context,
            test_path, filename, mode, arch))
      return tests

  def ListTests(self, current_path, path, mode, arch):
    tests = []
    for root, dirs, files in os.walk(join(self.root, 'src')):
      for f in [x for x in files if self.IsTest(x)]:
        if f.endswith(".dart"):
          test_path = current_path + [ f[:-5] ]  # Remove .dart suffix.
        elif f.endswith(".app"):
          test_path = current_path + [ f[:-4] ]  # Remove .app suffix.
        if not self.Contains(path, test_path):
          continue
        tests.extend(self.CreateTestCases(test_path, path, join(root, f),
                                          mode, arch))
    atexit.register(lambda: self._cleanup(tests))
    return tests

  def IsTest(self, name):
    return name.endswith('Test.dart') or name.endswith("Test.app")

  def GetTestStatus(self, sections, defs):
    status = join(self.root, basename(self.root) + '.status')
    if exists(status):
      test.ReadConfigurationInto(status, sections, defs)

  def FindReferencedFiles(self, lines):
    referenced_files = []
    for line in lines:
      m = re.match("#(source|import)\(['\"](.*)['\"]\);", line)
      if m:
        referenced_files.append(m.group(2))
    return referenced_files

  def SplitMultiTest(self, test_path, filename):
    (name, extension) = os.path.splitext(os.path.basename(filename))
    with open(filename, 'r') as s:
      source = s.read()
    lines = source.splitlines()
    tags = {}
    for line in lines:
      (code, sep, info) = line.partition(' /// ')
      if sep:
        (tag, sep, kind) = info.partition(': ')
        if tags.has_key(tag):
          raise utils.Error('duplicated tag %s' % tag)
        if kind not in StandardTestConfiguration.LEGAL_KINDS:
          raise utils.Error('unrecognized kind %s' % kind)
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

class BrowserTestCase(test_case.StandardTestCase):
  def __init__(self, context, path, filename,
               fatal_static_type_errors, mode, arch):
    super(test_case.BrowserTestCase, self).__init__(context, path, filename, mode, arch)
    self.fatal_static_type_errors = fatal_static_type_errors

  def IsBatchable(self):
    return True
      
  def Run(self):
    command = self.run_arch.GetCompileCommand(self.fatal_static_type_errors)
    if command != None:
      # We change the directory where dartc will be launched because
      # it is not predictable on the location of the compiled file. In
      # case the test is a web test, we make sure the app file is not
      # in a subdirectory.
      cwd = None
      if self.run_arch.is_web_test: cwd = self.run_arch.temp_dir
      command = command[:1] + self.context.flags + command[1:]
      test_output = self.RunCommand(command, cwd=cwd)

      # If errors were found, fail fast and show compile errors:
      if test_output.output.exit_code != 0:
        if not self.context.keep_temporary_files:
          self.run_arch.Cleanup()
        return test_output

    command = self.run_arch.GetRunCommand();
    test_output = self.RunCommand(command)
    # The return value of DumpRenderedTree does not indicate test failing, but
    # the output does.
    if self.run_arch.HasFailed(test_output.output.stdout):
      test_output.output.exit_code = 1

    # TODO(ngeoffray): We run out of space on the build bots for these tests if
    # the temp directories are not removed right after running the test.
    if not self.context.keep_temporary_files:
      self.run_arch.Cleanup()

    return test_output


class BrowserTestConfiguration(StandardTestConfiguration):
  def __init__(self, context, root, fatal_static_type_errors=False):
    super(BrowserTestConfiguration, self).__init__(context, root)
    self.fatal_static_type_errors = fatal_static_type_errors

  def ListTests(self, current_path, path, mode, arch):
    tests = []
    for root, dirs, files in os.walk(self.root):
      for f in [x for x in files if self.IsTest(x)]:
        relative = os.path.relpath(root, self.root).split(os.path.sep)
        test_path = current_path + relative + [os.path.splitext(f)[0]]
        if not self.Contains(path, test_path):
          continue
        tests.append(test_case.BrowserTestCase(self.context,
            test_path, join(root, f), self.fatal_static_type_errors, mode,
            arch))
    atexit.register(lambda: self._cleanup(tests))
    return tests

  def IsTest(self, name):
    return name.endswith('_tests.dart')


class CompilationTestConfiguration(test.TestConfiguration):
  """ Configuration that searches specific directories for apps to compile

      Expects a status file named  dartc.status
  """
  def __init__(self, context, root):
    super(CompilationTestConfiguration, self).__init__(context, root)

  def ListTests(self, current_path, path, mode, arch):
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
          filename.append(f) # Remove .lib or .app suffix.
          test_path = current_path + filename
          test_dart_file = os.path.join(root, f)
          if ((not self.Contains(path, test_path)) 
              or (not self.IsTest(test_dart_file))):
            continue
          tests.append(test_case.CompilationTestCase(test_path,
                                           self.context,
                                           test_dart_file,
                                           mode,
                                           arch))
    atexit.register(lambda: self._cleanup(tests))
    return tests

  def SourceDirs(self):
    """ Returns a list of directories to scan for files to compile """
    raise TestConfigurationError(
        "Subclasses must implement SourceDirs()")

  def IsTest(self, name):
    if (not name.endswith('.dart')):
      return False
    if (os.path.exists(name)):
      # TODO(dgrove): can we end reading the input early?
      for line in fileinput.input(name):
        if (re.match('#', line)):
          fileinput.close()
          return True
      fileinput.close()
      return False
    return False

  def GetTestStatus(self, sections, defs):
    status = os.path.join(self.root, 'dartc.status')
    if os.path.exists(status):
      test.ReadConfigurationInto(status, sections, defs)

  def _cleanup(self, tests):
    if not utils.Daemonize(): return
    os.execlp('rm', *(['rm', '-rf'] + [t.temp_dir for t in tests]))
    raise
