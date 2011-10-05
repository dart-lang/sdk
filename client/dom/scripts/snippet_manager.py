#!/usr/bin/python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

import logging.config
import os
import sys
import re

_logger = logging.getLogger('snippet_manager')

# Regular expression to find method signatures in dart snippet files.
# (find unindented lines that end with a {)
METHOD_SIGNATURE_RE = re.compile(r'(\S[^{]*){')

class SnippetManager(object):
  """The SnippetManager loads all the files in the snippets directory
  and searches for method signatures.  These will be inserted
  into the Dart interfaces that dartdomgenerator.py produces.
  """
  def __init__(self, root_dir):
    self._root_dir = root_dir

    # map from interface name to snippet text
    self.snippet_map = {}
    self._load()

  def _load(self):
    res = []
    def visitor(arg, dirname, names):
      for name in list(names):
        if name == ".svn":
          names.remove(name);
          continue;
        path = os.path.join(dirname, name)
        if os.path.isdir(path):
          continue
        self._load_file(path)
    os.path.walk(self._root_dir, visitor, None)

  def _load_file(self, path):
    match = re.compile(r'.*/(.*?)(Impl)?.dart.snippet').match(path)
    if match is None:
      raise RuntimeError('bad snippet filename "%s"' % (path))
    interface_name = match.group(1)
    is_impl = match.group(2)
    _logger.info("processing snippet file %s" % path)
    f = open(path, 'r')

    if not self.snippet_map.has_key(interface_name):
      self.snippet_map[interface_name] = ''
    if is_impl:
      method_signatures = []
      for line in f.readlines():
        match = METHOD_SIGNATURE_RE.match(line)
        if match:
          method_signatures.append(match.group(1).strip() + ";")
      if len(method_signatures) > 0:
        self.snippet_map[interface_name] += "\n".join(method_signatures)
    else:
      self.snippet_map[interface_name] += f.read()

def main():
  """Used for debugging to dump all the snippets.
  """
  current_dir = os.path.dirname(__file__)
  logging.config.fileConfig(os.path.join(current_dir, "logging.conf"))
  snippet_dir = os.path.join(current_dir, '..', 'snippets')
  snippet_manager = SnippetManager(snippet_dir)
  for interface_name, snippet in snippet_manager.snippet_map.items():
    print '---'
    print '%s:' % interface_name
    print snippet

if __name__ == "__main__":
    sys.exit(main())
