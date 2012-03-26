#!/usr/bin/python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

# Template loader and preprocessor.
#
# Preprocessor language:
#
#   $if VAR
#   $else
#   $endif
#
# VAR must be defined in the conditions dictionary.

import os

class TemplateLoader(object):
  """Loads template files from a path."""

  def __init__(self, root, subpaths, conditions = {}):
    """Initializes loader.

    Args:
      root - a string, the directory under which the templates are stored.
      subpaths - a list of strings, subpaths of root in search order.
      conditions - a dictionay from strings to booleans.  Any conditional
        expression must be a key in the map.
    """
    self._root = root
    self._subpaths = subpaths
    self._conditions = conditions
    self._cache = {}

  def TryLoad(self, name):
    """Returns content of template file as a string, or None of not found."""
    if name in self._cache:
      return self._cache[name]

    for subpath in self._subpaths:
      template_file = os.path.join(self._root, subpath, name)
      if os.path.exists(template_file):
        template = ''.join(open(template_file).readlines())
        template = self._Preprocess(template, template_file)
        self._cache[name] = template
        return template

    return None

  def Load(self, name):
    """Returns contents of template file as a string, or raises an exception."""
    template = self.TryLoad(name)
    if template is not None:  # Can be empty string
      return template
    raise Exception("Could not find template '%s' on %s / %s" % (
        name, self._root, self._subpaths))

  def _Preprocess(self, template, filename):
    def error(lineno, message):
      raise Exception('%s:%s: %s' % (filename, lineno, message))

    lines = template.splitlines(True)
    out = []

    condition_stack = []
    active = True
    seen_else = False

    for (lineno, full_line) in enumerate(lines):
      line = full_line.strip()

      if line.startswith('$'):
        words = line.split()
        directive = words[0]

        if directive == '$if':
          if len(words) != 2:
            error(lineno, '$if does not have single variable')
          variable = words[1]
          if variable in self._conditions:
            condition_stack.append((active, seen_else))
            active = self._conditions[variable]
            seen_else = False
          else:
            error(lineno, "Unknown $if variable '%s'" % variable)

        elif directive == '$else':
          if not condition_stack:
            error(lineno, '$else without $if')
          if seen_else:
            raise error(lineno, 'Double $else')
          seen_else = True
          active = not active

        elif directive == '$endif':
          if not condition_stack:
            error(lineno, '$endif without $if')
          (active, seen_else) = condition_stack.pop()

        else:
          # Something else, like '$!MEMBERS'
          if active:
            out.append(full_line)

      else:
        if active:
          out.append(full_line);
        continue

    if condition_stack:
      error(len(lines), 'Unterminated $if')

    return ''.join(out)
