# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.


import os
from os.path import join, exists
import re

import test
import utils


class Error(Exception):
  pass


class Co19TestCase(test.TestCase):
  def __init__(self, path, context, filename, mode, arch, component):
    super(Co19TestCase, self).__init__(context, path)
    self.filename = filename
    self.mode = mode
    self.arch = arch
    self.component = component
    self._is_negative = None

  def IsNegative(self):
    if self._is_negative is None :
      contents = self.GetSource()
      if '@compile-error' in contents or '@runtime-error' in contents:
        self._is_negative = True
      elif '@dynamic-type-error' in contents:
        self._is_negative = self.context.checked
      else:
        self._is_negative = False
    return self._is_negative

  def GetLabel(self):
    return "%s%s %s %s" % (self.mode, self.arch, self.component,
                           "/".join(self.path))

  def GetCommand(self):
    # Parse the options by reading the .dart source file.
    source = self.GetSource()
    vm_options = utils.ParseTestOptions(test.VM_OPTIONS_PATTERN, source,
                                        self.context.workspace)
    dart_options = utils.ParseTestOptions(test.DART_OPTIONS_PATTERN, source,
                                          self.context.workspace)

    # Combine everything into a command array and return it.
    command = self.context.GetDart(self.mode, self.arch, self.component)
    command += self.context.flags
    if self.mode == 'release': command += ['--optimize']
    if vm_options: command += vm_options
    if dart_options: command += dart_options
    else:
      command += [self.filename]
    return command

  def GetName(self):
    return self.path[-1]

  def GetPath(self):
    return os.path.dirname(self.filename)

  def GetSource(self):
    return file(self.filename).read()


class Co19TestConfiguration(test.TestConfiguration):
  def __init__(self, context, root):
    super(Co19TestConfiguration, self).__init__(context, root)

  def ListTests(self, current_path, path, mode, arch, component):
    tests = []
    src_dir = join(self.root, "src")
    strip = len(src_dir.split(os.path.sep))
    for root, dirs, files in os.walk(src_dir):
      ignore_dirs = [d for d in dirs if d.startswith('.')]
      for d in ignore_dirs:
        dirs.remove(d)
      for f in [x for x in files if self.IsTest(x)]:
        test_path = [] + current_path
        test_path.extend(root.split(os.path.sep)[strip:])
        test_name = short_name = f

        # shotlen test_name
        # remove repeats
        if short_name.startswith(test_path[-1]):
          short_name = short_name[len(test_path[-1]) : ]

        # remove suffixes
        if short_name.endswith(".dart"):
          short_name = short_name[:-5]  # Remove .dart suffix.
        # now .app suffix discarded at self.IsTest()
        #elif short_name.endswith(".app"):
        #  short_name = short_name[:-4]  # Remove .app suffix.
        else:
          raise Error('Unknown suffix in "%s", fix IsTest() predicate' % f)


        while short_name.startswith('_'):
          short_name = short_name[1:]

        test_path.extend(short_name.split('_'))

        # test full name and shorted name matches given path pattern
        if self.Contains(path, test_path): pass
        elif self.Contains(path, test_path + [test_name]): pass
        else:
          continue

        tests.append(Co19TestCase(test_path,
                                  self.context,
                                  join(root, f),
                                  mode,
                                  arch,
                                  component))
    return tests

  _TESTNAME_PATTERN = re.compile(r'.*_t[0-9]{2}\.dart$')
  def IsTest(self, name):
    return self._TESTNAME_PATTERN.match(name)

  def GetTestStatus(self, sections, defs):
    status = join(self.root, "co19-runtime.status")
    if exists(status):
      test.ReadConfigurationInto(status, sections, defs)
    status = join(self.root, "co19-compiler.status")
    if exists(status):
      test.ReadConfigurationInto(status, sections, defs)
    status = join(self.root, "co19-frog.status")
    if exists(status):
      test.ReadConfigurationInto(status, sections, defs)

  def Contains(self, path, file):
    """ reimplemented for support '**' glob pattern """
    if len(path) > len(file):
      return
    # ** matches to any number of directories, a/**/d matches a/b/c/d
    # paths like a/**/x/**/b not allowed
    patterns = [p.pattern for p in path]
    if '**' in patterns:
      idx = patterns.index('**')
      patterns[idx : idx] = ['*'] * (len(file) - len(path))
      path = [test.Pattern(p) for p in patterns]

    for i in xrange(len(path)):
      if not path[i].match(file[i]):
        return False
    return True

def GetConfiguration(context, root):
  return Co19TestConfiguration(context, root)
