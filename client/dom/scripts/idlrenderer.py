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

  def wsp(node):
    """Writes the given node and adds a space if there was output."""
    mark = len(output)
    w(node)
    if mark != len(output):
      w(' ')

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
      wsp(node.annotations)
      wsp(node.ext_attrs)
      wln('module %s {' % node.id)
      begin_indent()
      w(node.interfaces)
      w(node.typeDefs)
      end_indent()
      wln('};')
    elif isinstance(node, IDLInterface):
      if node.annotations:
        wln(node.annotations)
      if node.ext_attrs:
        wln(node.ext_attrs)
      w('interface %s' % node.id)
      begin_indent()
      begin_indent()
      if node.parents:
        wln(' :')
        w(node.parents, ',\n')
      wln(' {')
      end_indent()
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
      end_indent()
      wln('};')
    elif isinstance(node, IDLParentInterface):
      wsp(node.annotations)
      w(node.type.id)
    elif isinstance(node, IDLAnnotations):
      sep = ''
      for (name, annotation) in sorted(node.items()):
        w(sep)
        sep = ' '
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
            if isinstance(v, IDLExtAttrFunctionValue):
              if v.id:
                w('=')
              w(v)
            else:
              w('=%s' % v.__str__())
          i += 1
        w(']')
    elif isinstance(node, IDLExtAttrFunctionValue):
      if node.id:
        w(node.id)
      w('(')
      w(node.arguments, ', ')
      w(')')
    elif isinstance(node, IDLAttribute):
      wsp(node.annotations)
      wsp(node.ext_attrs)
      if node.is_fc_getter:
        w('getter ')
      if node.is_fc_setter:
        w('setter ')
      w('attribute %s %s' % (node.type.id, node.id))
      if node.raises:
        w(' raises (%s)' % node.raises.id)
      elif node.is_fc_getter and node.get_raises:
        w(' getraises (%s)' % node.get_raises.id)
      elif node.is_fc_setter and node.set_raises:
        w(' setraises (%s)' % node.set_raises.id)
      wln(';')
    elif isinstance(node, IDLConstant):
      wsp(node.annotations)
      wsp(node.ext_attrs)
      wln('const %s %s = %s;' % (node.type.id, node.id, node.value))
    elif isinstance(node, IDLOperation):
      wsp(node.annotations)
      wsp(node.ext_attrs)
      if node.is_static:
        w('static ')
      if node.specials:
        w(node.specials, ' ')
        w(' ')
      w('%s ' % node.type.id)
      w(node.id)
      w('(')
      w(node.arguments, ', ')
      w(')')
      if node.raises:
        w(' raises (%s)' % node.raises.id)
      wln(';')
    elif isinstance(node, IDLArgument):
      wsp(node.ext_attrs)
      w('in ')
      if node.is_optional:
        w('optional ')
      w('%s %s' % (node.type.id, node.id))
    else:
      raise TypeError("Expected str or IDLNode but %s found" %
        type(node))

  w(idl_node)
  return ''.join(output)
