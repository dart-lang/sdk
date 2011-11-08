# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import os
import re
import shutil
import sys
import tempfile

import test
from testing import test_case,test_configuration
import utils

from os.path import join, exists, isdir

def GeneratedName(src):
  return re.sub('\.dart$', '-generatedTest.dart', src)

class DartStubTestCase(test_case.StandardTestCase):
  def __init__(self, context, path, filename, mode, arch, component):
    super(DartStubTestCase, self).__init__(context, path, filename, mode, arch,
                                           component)
    self.filename = filename
    self.mode = mode
    self.arch = arch
    self.component = component

  def IsBatchable(self):
    return False

  def GetStubs(self):
    source = self.GetSource()
    stub_classes = utils.ParseTestOptions(test.ISOLATE_STUB_PATTERN, source,
                                          self.context.workspace)
    if stub_classes is None:
      return (None, None, None)
    (interface, _, classes) = stub_classes[0].partition(':')
    (interface, _, implementation) = interface.partition('+')
    return (interface, classes, implementation)

  def IsFailureOutput(self, output):
    return output.exit_code != 0 or not '##DONE##' in output.stdout

  def BeforeRun(self):
    if not self.context.generate:
      return
    (interface, classes, _) = self.GetStubs()
    if interface is None:
      return
    d = join(self.GetPath(), 'generated')
    if not isdir(d):
      os.mkdir(d)
    tmpdir = tempfile.mkdtemp()
    src = join(self.GetPath(), interface)
    dest = join(self.GetPath(), GeneratedName(interface))
    (_, tmp) = tempfile.mkstemp()
    command = self.context.GetDartC(self.mode, self.arch)
    self.RunCommand(command + [ src,
                                # dartc generates output even if it has no
                                # output to generate.
                                '-noincremental',
                                '-out', tmpdir,
                                '-isolate-stub-out', tmp,
                                '-generate-isolate-stubs', classes ])
    shutil.rmtree(tmpdir)

    # Copy comments and # commands from the beginning of the source to
    # the beginning of the generated file, then copy the remaining
    # source to the end.
    d = open(dest, 'w')
    s = open(src, 'r')
    t = open(tmp, 'r')
    while True:
      line = s.readline()
      if not (re.match('^\s+$', line) or line.startswith('//')
              or line.startswith('#')):
        break
      d.write(line)
    d.write(t.read())
    os.remove(tmp)
    d.write(line)
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
    command = self.context.GetDart(self.mode, self.arch, self.component)
    if interface is None:
      f = self.filename
    else:
      f = GeneratedName(interface)
    files = [ join(self.GetPath(), f) ]
    if vm_options: command += vm_options
    if dart_options: command += dart_options
    else: command +=  files
    return command


class DartStubTestConfiguration(test_configuration.StandardTestConfiguration):
  def __init__(self, context, root):
    super(DartStubTestConfiguration, self).__init__(context, root)

  def ListTests(self, current_path, path, mode, arch, component):
    dartc = self.context.GetDartC(mode, arch)
    self.context.generate = os.access(dartc[0], os.X_OK)
    tests = []
    for root, dirs, files in os.walk(join(self.root, 'src')):
      # Skip remnants from the subdirectory that used to be used for
      # generated code.
      if root.endswith('generated'):
        continue
      for f in [x for x in files if self.IsTest(x)]:
        # If we can generate code, do not use the checked-in generated
        # code.  Conversely, if we cannot, then only use the
        # checked-in generated code.
        if self.context.generate == f.endswith('-generatedTest.dart'):
          continue
        test_path = current_path + [ f[:-5] ]  # Remove .dart suffix.
        if not self.Contains(path, test_path):
          continue
        tests.append(DartStubTestCase(self.context,
                                      test_path,
                                      join(root, f),
                                      mode,
                                      arch,
                                      component))
    return tests


def GetConfiguration(context, root):
  return DartStubTestConfiguration(context, root)
