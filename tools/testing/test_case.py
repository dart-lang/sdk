# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""Common TestCase subclasses used to define a single test."""

import os
import tempfile

import test
from testing import architecture


class Error(Exception):
  pass


class StandardTestCase(test.TestCase):
  """A test case defined by a *Test.dart file."""

  def __init__(self, context, path, filename, mode, arch, vm_options=None):
    super(StandardTestCase, self).__init__(context, path)
    self.filename = filename
    self.mode = mode
    self.arch = arch
    self.run_arch = architecture.GetArchitecture(self.arch, self.mode,
                                                 self.filename)
    for flag in context.flags:
      self.run_arch.vm_options.append(flag)

    if vm_options:
      for flag in vm_options:
        self.run_arch.vm_options.append(flag)

  def IsNegative(self):
    return self.GetName().endswith('NegativeTest')

  def GetLabel(self):
    return '%s%s %s' % (self.mode, self.arch, '/'.join(self.path))

  def GetCommand(self):
    return self.run_arch.GetRunCommand()

  def GetName(self):
    return self.path[-1]

  def GetPath(self):
    return os.path.dirname(self.filename)

  def GetSource(self):
    return file(self.filename).read()

  def Cleanup(self):
    # TODO(ngeoffray): We run out of space on the build bots for these tests if
    # the temp directories are not removed right after running the test.
    if not self.context.keep_temporary_files:
      self.run_arch.Cleanup()


class MultiTestCase(StandardTestCase):
  """Multiple test cases defined within a single *Test.dart file."""

  def __init__(self, context, path, filename, kind, mode, arch):
    super(MultiTestCase, self).__init__(context, path, filename, mode, arch)
    self.kind = kind

  def GetCommand(self):
    """Returns a commandline to execute to perform the test."""
    return self.run_arch.GetRunCommand(
        fatal_static_type_errors=(self.kind == 'static type error'))

  def IsNegative(self):
    """Determine if this is a negative test. by looking at @ directives.

    A negative test is considered to pas if its outcome is FAIL.

    Returns:
      True if this is a negative test.
    """
    if self.kind == 'compile-time error':
      return True
    if self.kind == 'runtime error':
      return False
    if self.kind == 'static type error':
      return self.run_arch.HasFatalTypeErrors()
    return False


class BrowserTestCase(StandardTestCase):
  """A test case that executes inside a browser (or DumpRenderTree)."""

  def __init__(self, context, path, filename,
               fatal_static_type_errors, mode, arch):
    super(BrowserTestCase, self).__init__(context, path, filename, mode, arch)
    self.fatal_static_type_errors = fatal_static_type_errors

  def Run(self):
    """Optionally compiles and then runs the specified test."""
    command = self.run_arch.GetCompileCommand(self.fatal_static_type_errors)
    if command:
      # We change the directory where dartc will be launched because
      # it is not predictable on the location of the compiled file. In
      # case the test is a web test, we make sure the app file is not
      # in a subdirectory.
      cwd = None
      if self.run_arch.is_web_test: cwd = self.run_arch.temp_dir
      command = command[:1] + self.context.flags + command[1:]
      test_output = self.RunCommand(command, cwd=cwd, cleanup=False)

      # If errors were found, fail fast and show compile errors:
      if test_output.output.exit_code != 0:
        return test_output

    command = self.run_arch.GetRunCommand()
    test_output = self.RunCommand(command)
    # The return value of DumpRenderedTree does not indicate test failing, but
    # the output does.
    if self.run_arch.HasFailed(test_output.output.stdout):
      test_output.output.exit_code = 1

    return test_output


class CompilationTestCase(test.TestCase):
  """Run the dartc compiler on a given top level .dart file."""

  def __init__(self, path, context, filename, mode, arch):
    super(CompilationTestCase, self).__init__(context, path)
    self.filename = filename
    self.mode = mode
    self.arch = arch
    self.run_arch = architecture.GetArchitecture(self.arch, self.mode,
                                                 self.filename)
    self.temp_dir = tempfile.mkdtemp(prefix='dartc-output-')

  def IsNegative(self):
    return False

  def GetLabel(self):
    return '%s/%s %s' % (self.mode, self.arch, '/'.join(self.path))

  def GetCommand(self):
    """Returns a command line to run the test."""
    cmd = self.context.GetDartC(self.mode, self.arch)
    cmd += self.context.flags
    cmd += ['-check-only',
            '-fatal-type-errors',
            '-Werror',
            '-out', self.temp_dir,
            self.filename]

    return cmd

  def GetName(self):
    return self.path[-1]
