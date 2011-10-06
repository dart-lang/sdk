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
import sys
import tempfile

import test
import utils

from os.path import join, exists, basename

import utils

class Error(Exception):
  pass


class StandardTestCase(test.TestCase):
  def __init__(self, context, path, filename, mode, arch):
    super(StandardTestCase, self).__init__(context, path)
    self.filename = filename
    self.mode = mode
    self.arch = arch
    self.run_arch = run.GetArchitecture(self.arch, self.mode, self.filename)
    for flag in context.flags:
      self.run_arch.vm_options.append(flag)

  def IsNegative(self):
    return self.GetName().endswith("NegativeTest")

  def GetLabel(self):
    return "%s%s %s" % (self.mode, self.arch, '/'.join(self.path))

  def GetCommand(self):
    return self.run_arch.GetRunCommand();

  def GetName(self):
    return self.path[-1]

  def GetPath(self):
    return os.path.dirname(self.filename)

  def GetSource(self):
    return file(self.filename).read()

  def Cleanup(self):
    # TODO(ngeoffray): We run out of space on the build bots for these tests if
    # the temp directories are not removed right after running the test.
    if not self.context.keep_temporary_files: self.run_arch.Cleanup()


class MultiTestCase(StandardTestCase):

  def __init__(self, context, path, filename, kind, mode, arch):
    super(MultiTestCase, self).__init__(context, path, filename, mode, arch)
    self.kind = kind

  def GetCommand(self):
    return self.run_arch.GetRunCommand(
      fatal_static_type_errors=(self.kind == 'static type error'));

  def IsNegative(self):
    if self.kind == 'compile-time error':
      return True
    if self.kind == 'runtime error':
      return False
    if self.kind == 'static type error':
      return self.run_arch.HasFatalTypeErrors()
    return False

class BrowserTestCase(StandardTestCase):
  def __init__(self, context, path, filename,
               fatal_static_type_errors, mode, arch):
    super(BrowserTestCase, self).__init__(context, path, filename, mode, arch)
    self.fatal_static_type_errors = fatal_static_type_errors


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
        return test_output

    command = self.run_arch.GetRunCommand();
    test_output = self.RunCommand(command)
    # The return value of DumpRenderedTree does not indicate test failing, but
    # the output does.
    if self.run_arch.HasFailed(test_output.output.stdout):
      test_output.output.exit_code = 1

    return test_output


class CompilationTestCase(test.TestCase):
  """ Run the dartc compiler on a given top level dart file """
  def __init__(self, path, context, filename, mode, arch):
    super(CompilationTestCase, self).__init__(context, path)
    self.filename = filename
    self.mode = mode
    self.arch = arch
    self.run_arch = run.GetArchitecture(self.arch, self.mode,
                                        self.filename)
    self.temp_dir = tempfile.mkdtemp(prefix='dartc-output-')

  def IsNegative(self):
    return False

  def GetLabel(self):
    return "%s/%s %s" % (self.mode, self.arch, '/'.join(self.path))

  def GetCommand(self):
    cmd = self.context.GetDartC(self.mode, self.arch);
    cmd += self.context.flags
    cmd += ['-check-only',
            '-fatal-type-errors',
            '-Werror',
            '-out', self.temp_dir,
            self.filename]

    return cmd

  def GetName(self):
    return self.path[-1]
