#!/usr/bin/env python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

from __future__ import with_statement
import StringIO
import os
import sys

class GenerateError(Exception):

  def __init__(self, value):
    self.value = value

  def __str__(self):
    return repr(self.value)


class Generator:

  def __init__(self, base_directory, name, output, path, *excludes):
    self.base_directory = base_directory
    self.name = name
    self.output = output
    self.path = path
    self.excludes = set()
    for x in excludes:
      self.excludes.add(x)
    self.sources = []
    self.resources = []

  def _list_files(self):
    start_directory = os.path.join(self.base_directory, self.path)
    for fullpath, dirs, filenames in os.walk(start_directory):
      path = fullpath[len(start_directory) + 1:]
      remove_me = [d for d in dirs if d.startswith('.') or
          d == 'CVS' or
          (d in self.excludes)]
      for d in remove_me:
        dirs.remove(d)
      for filename in filenames:
        if (filename.endswith('.java')):
          self.sources.append(os.path.join(path, filename))
        elif (filename.endswith('~')):
          pass
        elif (filename.endswith('.pyc')):
          pass
        else:
          self.resources.append(os.path.join(path, filename))
    self.sources.sort()
    self.resources.sort()

  def _print_gypi_files(self, out, name, files):
    out.write("    '%s': [\n" % name)
    for filename in files:
      out.write('''      r'%s/%s',%s''' % (self.path, filename,'\n'))
    out.write("    ],\n")

  def _print_txt_files(self, out, files):
    for filename in files:
      out.write('%s\n' % os.path.join(self.path, filename))

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

    file_name = self.output + '.gypi'
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

    file_name = self.output + '.txt'
    txt = self._make_output(file_name)
    self._print_txt_files(txt, self.sources)
    self._close(file_name, txt)


def Main(script_name = None, name = None, output = None, path = None,
         *rest):
  if not path:
    raise GenerateError("usage: %s NAME OUTPUT PATH EXCLUDE_DIR_NAME ..."
                        % script_name)
  base_directory = os.path.dirname(output)
  Generator(base_directory, name, output, path, *rest).generate()


if __name__ == '__main__':
  sys.exit(Main(*sys.argv))
