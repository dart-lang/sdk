# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import os
from os.path import join, exists

import test
from testing import test_runner

class VmTestCase(test.TestCase):
  def __init__(self, path, context, mode, arch, flags):
    super(VmTestCase, self).__init__(context, path)
    self.mode = mode
    self.arch = arch
    self.flags = flags

  def IsNegative(self):
    # TODO(kasperl): Figure out how to support negative tests. Maybe
    # just have a TEST_CASE_NEGATIVE macro?
    return False

  def GetLabel(self):
    return '%s%s vm %s' % (self.mode, self.arch, '/'.join(self.path))

  def GetCommand(self):
    command = self.context.GetRunTests(self.mode, self.arch)
    command += [ self.GetName() ]
    # Add flags being set in the context.
    for flag in self.context.flags:
      command.append(flag)
    if self.flags: command += self.flags
    return command

  def GetName(self):
    return self.path[-1]


class VmTestConfiguration(test.TestConfiguration):
  def __init__(self, context, root):
    super(VmTestConfiguration, self).__init__(context, root)

  def ListTests(self, current_path, path, mode, arch, component):
    if component != 'vm': return []
    run_tests = self.context.GetRunTests(mode, arch)
    output = test_runner.Execute(run_tests + ['--list'], self.context)
    if output.exit_code != 0:
      print output.stdout
      print output.stderr
      return [ ]
    tests = [ ]
    for test_line in output.stdout.strip().split('\n'):
      name_and_flags = test_line.split()
      name = name_and_flags[0]
      flags = name_and_flags[1:]
      test_path = current_path + [name]
      if self.Contains(path, test_path):
        tests.append(VmTestCase(test_path, self.context, mode, arch, flags))
    return tests

  def GetTestStatus(self, sections, defs):
    status = join(self.root, 'vm.status')
    if exists(status): test.ReadConfigurationInto(status, sections, defs)


def GetConfiguration(context, root):
  return VmTestConfiguration(context, root)
