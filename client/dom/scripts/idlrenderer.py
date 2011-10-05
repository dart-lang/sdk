#!/usr/bin/python
# Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

from idlnode import *


def render(idl_node, indent_str='  '):
  output = []
  indent_stack = []

  def begin_indent():
    indent_stack.append(indent_str)

  def end_indent():
    indent_stack.pop()

  def sort(nodes):
    return sorted(nodes, key=lambda node: node.id)

  def wln(node=None):
    """Writes the given node and adds a new line."""
    w(node)
    output.append('\n')

  def w(node, list_separator=None):
    """Writes the given node.

    Args:
      node -- a string, IDLNode instance or a list of such.
      list_separator -- if provided, and node is a list,
        list_separator will be written between the list items.
    """
    if node is None:
      return
    elif isinstance(node, str):
      if output and output[-1].endswith('\n'):
        # Auto-indent.
        output.extend(indent_stack)
      output.append(node)
    elif isinstance(node, list):
      for i in range(0, len(node)):
        if i > 0:
          w(list_separator)
        w(node[i])
    elif isinstance(node, IDLFile):
      w(node.modules)
      w(node.interfaces)
    elif isinstance(node, IDLModule):
      w(node.annotations)
      w(node.ext_attrs)
      wln('module %s {' % node.id)
      begin_indent()
      w(node.interfaces)
      w(node.typeDefs)
      end_indent()
      wln('};')
    elif isinstance(node, IDLInterface):
      w(node.annotations)
      w(node.ext_attrs)
      w('interface %s' % node.id)
      begin_indent()
      if node.parents:
        wln(' :')
        w(node.parents, ',\n')
      wln(' {')
      if node.constants:
        wln()
        wln('/* Constants */')
        w(sort(node.constants))
      if node.attributes:
        wln()
        wln('/* Attributes */')
        w(sort(node.attributes))
      if node.operations:
        wln()
        wln('/* Operations */')
        w(sort(node.operations))
      if node.snippets:
        wln()
        wln('/* Snippets */')
        w(sort(node.snippets))
      end_indent()
      wln('};')
    elif isinstance(node, IDLParentInterface):
      w(node.annotations)
      w(node.type.id)
    elif isinstance(node, IDLAnnotations):
      for (name, annotation) in sorted(node.items()):
        if annotation and len(annotation):
          subRes = []
          for (argName, argValue) in sorted(annotation.items()):
            if argValue is None:
              subRes.append(argName)
            else:
              subRes.append('%s=%s' % (argName, argValue))
          w('@%s(%s)' % (name, ', '.join(subRes)))
        else:
          w('@%s' % name)
        w(' ')
    elif isinstance(node, IDLExtAttrs):
      if len(node):
        w('[')
        i = 0
        for k in sorted(node):
          if i > 0:
            w(', ')
          w(k)
          v = node[k]
          if v is not None:
            w('=%s' % v.__str__())
          i += 1
        w('] ')
    elif isinstance(node, IDLAttribute):
      w(node.annotations)
      w(node.ext_attrs)
      if node.is_fc_getter:
        w('getter ')
      if node.is_fc_setter:
        w('setter ')
      wln('attribute %s %s;' % (node.type.id, node.id))
    elif isinstance(node, IDLConstant):
      w(node.annotations)
      w(node.ext_attrs)
      wln('const %s %s = %s;' % (node.type.id, node.id, node.value))
    elif isinstance(node, IDLSnippet):
      w(node.annotations)
      wln('snippet {%s};' % node.text)
    elif isinstance(node, IDLOperation):
      w(node.annotations)
      w(node.ext_attrs)
      if node.specials:
        w(node.specials, ' ')
        w(' ')
      w('%s ' % node.type.id)
      w(node.id)
      w('(')
      w(node.arguments, ', ')
      wln(');')
    elif isinstance(node, IDLArgument):
      w(node.ext_attrs)
      w('in ')
      if node.is_optional:
        w('optional ')
      w('%s %s' % (node.type.id, node.id))
    else:
      raise TypeError("Expected str or IDLNode but %s found" %
        type(node))

  w(idl_node)
  return ''.join(output)
