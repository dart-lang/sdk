#!/usr/bin/env python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import StringIO
import os
import sys
import re
from collections import deque

class GenerateError(Exception):

  def __init__(self, value):
    self.value = value

  def __str__(self):
    return repr(self.value)


class Generator:

  def __init__(self, base_directory, name, output, path, *includes):
    self.base_directory = base_directory
    self.name = name
    self.output = output
    self.path = path
    self.includes = set()
    for x in includes:
      self.includes.add(x)
    self.sources = []
    self.resources = []

  def _list_files(self):
    drain = deque()
    drain.extend(self.includes)
    while len(drain) > 0:
      target = drain.popleft()
      # Avoid circular dependencies
      if target in self.resources:
        continue
      if (target.startswith("dart:")):
        continue
      self.resources.append(target)
      if (target.endswith(".dart")):
        with open(os.path.join(self.base_directory,self.path,target),"r") as fobj:
          text = fobj.read()
        file_sources = re.findall(r"#source\(['\"](?P<name>.*)['\"]\);",text)
        file_native = re.findall(r"#native\(['\"](?P<name>.*)['\"]\);",text)
        file_imports = re.findall(r"#import\(['\"](?P<name>.*)['\"]\);",text)
        self.resources.extend(file_sources)
        self.resources.extend(file_native)
        drain.extend(file_imports)
    self.sources.sort()
    self.resources.sort()

  def _print_gypi_files(self, out, name, files):
    out.write("    '%s': [\n" % name)
    for filename in files:
      out.write("      '%s/%s',\n" % (self.path, filename))
    out.write("    ],\n")

  def _print_ant_files(self, out, name, files):
    out.write("  <filelist id='%s' dir='%s'>\n" % (name, self.path))
    for filename in files:
      out.write("    <file name='%s'/>\n" % filename)
    out.write("  </filelist>\n")
    out.write("  <pathconvert pathsep=',' property='%s' refid='%s'>\n"
              % (name, name))
    out.write("    <map from='${basedir}/%s/' to=''/>\n" % self.path)
    out.write("  </pathconvert>\n")

  def _make_output(self, file_name):
    if os.path.exists(file_name):
      return StringIO.StringIO()
    else:
      return file(file_name, 'w')

  def _close(self, file_name, output):
    if not isinstance(output, StringIO.StringIO):
      output.close()
      return
    new_text = output.getvalue()
    output.close()
    with open(file_name, 'r') as f:
      old_text = f.read()
    if old_text == new_text:
      return
    sys.stderr.write('Updating %s\n' % file_name)
    with open(file_name, 'w') as f:
      f.write(new_text)

  def generate(self):
    self._list_files()
    file_name = self.output + '.gypi';
    gypi = self._make_output(file_name)
    gypi.write("{\n  'variables': {\n")
    self._print_gypi_files(gypi, self.name + '_sources', self.sources)
    self._print_gypi_files(gypi, self.name + '_resources', self.resources)
    gypi.write("  },\n}\n")
    self._close(file_name, gypi)
    file_name = self.output + '.xml'
    ant = self._make_output(file_name)
    ant.write("<project>\n")
    self._print_ant_files(ant, self.name + '_sources', self.sources)
    self._print_ant_files(ant, self.name + '_resources', self.resources)
    ant.write("</project>\n")
    self._close(file_name, ant)


def Main(script_name = None, name = None, output = None, path = None,
         *rest):
  if not path:
    raise GenerateError("usage: %s NAME OUTPUT PATH EXCLUDE_DIR_NAME ..."
                        % script_name)
  base_directory = os.path.dirname(output)
  Generator(base_directory, name, output, path, *rest).generate()


if __name__ == '__main__':
  sys.exit(Main(*sys.argv))
