# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import os
import re
import shutil
import tempfile
import test
import testing
import utils

from os.path import join, exists, isdir

class DartStubTestCase(testing.StandardTestCase):
  def __init__(self, context, path, filename, mode, arch):
    super(DartStubTestCase, self).__init__(context, path, filename, mode, arch)
    self.filename = filename
    self.mode = mode
    self.arch = arch

  def IsBatchable(self):
    return False

  def GetStubs(self):
    source = self.GetSource()
    stub_classes = utils.ParseTestOptions(test.ISOLATE_STUB_PATTERN, source,
                                          self.context.workspace)
    (interface, _, classes) = stub_classes[0].partition(':')
    (interface, _, implementation) = interface.partition('+')
    return (interface, classes, implementation)

  def IsFailureOutput(self, output):
    return output.exit_code != 0 or not '##DONE##' in output.stdout

  def BeforeRun(self):
    command = self.context.GetDartC(self.mode, 'dartc')
    (interface, classes, _) = self.GetStubs()
    d = join(self.GetPath(), 'generated')
    if not isdir(d):
      os.mkdir(d)
    tmpdir = tempfile.mkdtemp()
    src = join(self.GetPath(), interface)
    dest = join(self.GetPath(), 'generated', interface)
    self.RunCommand(command + [ src,
                                # dartc generates output even if it has no
                                # output to generate.
                                '-out', tmpdir,
                                '-isolate-stub-out', dest,
                                '-generate-isolate-stubs', classes ])
    shutil.rmtree(tmpdir)
    d = open(dest, 'a')
    s = open(src, 'r')
    d.write(s.read())

  def GetCommand(self):
    # Parse the options by reading the .dart source file.
    source = self.GetSource()
    vm_options = utils.ParseTestOptions(test.VM_OPTIONS_PATTERN, source,
                                        self.context.workspace)
    dart_options = utils.ParseTestOptions(test.DART_OPTIONS_PATTERN, source,
                                          self.context.workspace)
    (interface, _, implementation) = self.GetStubs()

    # Combine everything into a command array and return it.
    command = self.context.GetDart(self.mode, self.arch)
    files = [ join(self.GetPath(), 'generated', interface) ]
    if vm_options: command += vm_options
    if dart_options: command += dart_options
    else: command +=  files
    return command


class DartStubTestConfiguration(testing.StandardTestConfiguration):
  def __init__(self, context, root):
    super(DartStubTestConfiguration, self).__init__(context, root)

  def ListTests(self, current_path, path, mode, arch):
    dartc = self.context.GetDartC(mode, 'dartc')
    if not os.access(dartc[0], os.X_OK):
      return []
    tests = []
    for root, dirs, files in os.walk(join(self.root, 'src')):
      if root.endswith('/generated'):
        continue
      for f in [x for x in files if self.IsTest(x)]:
        test_path = current_path + [ f[:-5] ]  # Remove .dart suffix.
        if not self.Contains(path, test_path):
          continue
        tests.append(DartStubTestCase(self.context,
                                      test_path,
                                      join(root, f),
                                      mode,
                                      arch))
    return tests


def GetConfiguration(context, root):
  return DartStubTestConfiguration(context, root)
