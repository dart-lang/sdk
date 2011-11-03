#!/usr/bin/env python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import os
from os.path import join, exists
import re

import test
import utils



class JUnitTestCase(test.TestCase):
  def __init__(self, path, context, classnames, mode, arch):
    super(JUnitTestCase, self).__init__(context, path)
    self.classnames = classnames
    self.mode = mode
    self.arch = arch

  def IsBatchable(self):
    return False

  def IsNegative(self):
    return False

  def GetLabel(self):
    return "%s/%s %s" % (self.mode, self.arch, '/'.join(self.path))

  def GetClassPath(self):
    third_party = join(self.context.workspace, 'third_party')
    jars = ['args4j/2.0.12/args4j-2.0.12.jar',
            'guava/r09/guava-r09.jar',
            'json/r2_20080312/json.jar',
            'rhino/1_7R3/js.jar',
            'hamcrest/v1_3/hamcrest-core-1.3.0RC2.jar',
            'hamcrest/v1_3/hamcrest-generator-1.3.0RC2.jar',
            'hamcrest/v1_3/hamcrest-integration-1.3.0RC2.jar',
            'hamcrest/v1_3/hamcrest-library-1.3.0RC2.jar',
            'junit/v4_8_2/junit.jar']
    jars = [ join(third_party, jar) for jar in jars ]
    buildroot = utils.GetBuildRoot(self.context.os, self.mode, self.arch)
    dartc_classes = [ os.path.join(buildroot, 'compiler', 'lib', 'dartc.jar'),
                      os.path.join(buildroot, 'compiler', 'lib', 'corelib.jar') ]
    test_classes = os.path.join(buildroot, 'compiler-tests.jar')
    closure_jar = os.path.sep.join([buildroot, 'closure_out', 'compiler.jar'])
    return os.path.pathsep.join(
        dartc_classes + [test_classes] + [closure_jar] + jars)

  def GetCommand(self):
    test_py = join(join(self.context.workspace, 'tools'), 'test.py')
    d8 = self.context.GetD8(self.mode, self.arch)
    # Note that it is important to run all the JUnit tests in the same process.
    # This way we have a chance of causing problems with static state early.
    return ['java', '-ea', '-classpath', self.GetClassPath(),
            '-Dcom.google.dart.runner.d8=' + d8,
            '-Dcom.google.dart.corelib.SharedTests.test_py=' + test_py,
            'org.junit.runner.JUnitCore'] + self.classnames

  def GetName(self):
    return self.path[-1]


class JUnitTestConfiguration(test.TestConfiguration):
  def __init__(self, context, root):
    super(JUnitTestConfiguration, self).__init__(context, root)

  def ListTests(self, current_path, path, mode, arch, component):
    test_path = current_path + ['junit_tests']
    if not self.Contains(path, test_path):
      return []
    classes = []
    javatests_path = join(join(join(self.root, '..'), '..'), 'javatests')
    javatests_path = os.path.normpath(javatests_path)
    for root, dirs, files in os.walk(javatests_path):
      if root.endswith('com/google/dart/compiler/vm'):
        continue
      for f in [x for x in files if self.IsTest(x)]:
        classname = []
        classname.extend(root[len(javatests_path) + 1:].split(os.path.sep))
        classname.append(f[:-5]) # Remove .java suffix.
        classname = '.'.join(classname)
        if classname == 'com.google.dart.corelib.SharedTests':
          continue
        classes.append(classname)
    return [JUnitTestCase(test_path, self.context, classes, mode, arch)]

  def IsTest(self, name):
    return name.endswith('Tests.java')

  def GetTestStatus(self, sections, defs):
    status = join(self.root, 'dartc.status')
    if exists(status):
      test.ReadConfigurationInto(status, sections, defs)


def GetConfiguration(context, root):
  return JUnitTestConfiguration(context, root)
