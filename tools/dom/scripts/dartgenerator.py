#!/usr/bin/python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""This module generates Dart APIs from the IDL database."""

import emitter
import idlnode
import logging
import os
import re
import shutil
from generator import *

_logger = logging.getLogger('dartgenerator')

def MergeNodes(node, other):
  node.operations.extend(other.operations)
  for attribute in other.attributes:
    if not node.has_attribute(attribute):
      node.attributes.append(attribute)

  node.constants.extend(other.constants)

class DartGenerator(object):
  """Utilities to generate Dart APIs and corresponding JavaScript."""

  def __init__(self, logging_level=logging.WARNING):
    self._auxiliary_files = {}
    self._dart_templates_re = re.compile(r'[\w.:]+<([\w\.<>:]+)>')
    _logger.setLevel(logging_level)

  def _StripModules(self, type_name):
    return type_name.split('::')[-1]

  def _IsCompoundType(self, database, type_name):
    if IsRegisteredType(type_name):
      return True

    if type_name.endswith('?'):
      return self._IsCompoundType(database, type_name[:-len('?')])

    if type_name.endswith('[]'):
      return self._IsCompoundType(database, type_name[:-len('[]')])

    stripped_type_name = self._StripModules(type_name)
    if database.HasInterface(stripped_type_name):
      return True

    if database.HasEnum(stripped_type_name):
      return True

    dart_template_match = self._dart_templates_re.match(type_name)
    if dart_template_match:
      # Dart templates
      parent_type_name = type_name[0 : dart_template_match.start(1) - 1]
      sub_type_name = dart_template_match.group(1)
      return (self._IsCompoundType(database, parent_type_name) and
              self._IsCompoundType(database, sub_type_name))
    return False

  def _IsDartType(self, type_name):
    return '.' in type_name

  def LoadAuxiliary(self, auxiliary_dir):
    def Visitor(_, dirname, names):
      for name in names:
        if name.endswith('.dart'):
          name = name[0:-5]  # strip off ".dart"
        self._auxiliary_files[name] = os.path.join(dirname, name)
    os.path.walk(auxiliary_dir, Visitor, None)

  def FilterMembersWithUnidentifiedTypes(self, database):
    """Removes unidentified types.

    Removes constants, attributes, operations and parents with unidentified
    types.
    """

    for interface in database.GetInterfaces():
      def IsIdentified(idl_node):
        node_name = idl_node.id if idl_node.id else 'parent'
        for idl_type in idl_node.all(idlnode.IDLType):
          type_name = idl_type.id
          if (type_name is not None and
              self._IsCompoundType(database, type_name)):
            continue
          # Ignore constructor warnings.
          if not (interface.id in ['Window', 'WorkerContext',
              'WorkerGlobalScope'] and
              type_name.endswith('Constructor')):
            _logger.warn('removing %s in %s which has unidentified type %s' %
                       (node_name, interface.id, type_name))
          return False
        return True

      interface.constants = filter(IsIdentified, interface.constants)
      interface.attributes = filter(IsIdentified, interface.attributes)
      interface.operations = filter(IsIdentified, interface.operations)
      interface.parents = filter(IsIdentified, interface.parents)

  def FilterInterfaces(self, database,
                       and_annotations=[],
                       or_annotations=[],
                       exclude_displaced=[],
                       exclude_suppressed=[]):
    """Filters a database to remove interfaces and members that are missing
    annotations.

    The FremontCut IDLs use annotations to specify implementation
    status in various platforms. For example, if a member is annotated
    with @WebKit, this means that the member is supported by WebKit.

    Args:
      database -- the database to filter
      all_annotations -- a list of annotation names a member has to
        have or it will be filtered.
      or_annotations -- if a member has one of these annotations, it
        won't be filtered even if it is missing some of the
        all_annotations.
      exclude_displaced -- if a member has this annotation and it
        is marked as displaced it will always be filtered.
      exclude_suppressed -- if a member has this annotation and it
        is marked as suppressed it will always be filtered.
    """

    # Filter interfaces and members whose annotations don't match.
    for interface in database.GetInterfaces():
      def HasAnnotations(idl_node):
        """Utility for determining if an IDLNode has all
        the required annotations"""
        for a in exclude_displaced:
          if (a in idl_node.annotations
              and 'via' in idl_node.annotations[a]):
            return False
        for a in exclude_suppressed:
          if (a in idl_node.annotations
              and 'suppressed' in idl_node.annotations[a]):
            return False
        for a in or_annotations:
          if a in idl_node.annotations:
            return True
        if and_annotations == []:
          return False
        for a in and_annotations:
          if a not in idl_node.annotations:
            return False
        return True

      if HasAnnotations(interface):
        interface.constants = filter(HasAnnotations, interface.constants)
        interface.attributes = filter(HasAnnotations, interface.attributes)
        interface.operations = filter(HasAnnotations, interface.operations)
        interface.parents = filter(HasAnnotations, interface.parents)
      else:
        database.DeleteInterface(interface.id)

    self.FilterMembersWithUnidentifiedTypes(database)

  def Generate(self, database, super_database, generate_interface):
    self._database = database

    # Collect interfaces
    interfaces = []
    for interface in database.GetInterfaces():
      if not MatchSourceFilter(interface):
        # Skip this interface since it's not present in the required source
        _logger.info('Omitting interface - %s' % interface.id)
        continue
      interfaces.append(interface)

    # Render all interfaces into Dart and save them in files.
    for interface in self._PreOrderInterfaces(interfaces):
      interface_name = interface.id
      auxiliary_file = self._auxiliary_files.get(interface_name)
      if auxiliary_file is not None:
        _logger.info('Skipping %s because %s exists' % (
            interface_name, auxiliary_file))
        continue

      _logger.info('Generating %s' % interface.id)
      generate_interface(interface)

  def _PreOrderInterfaces(self, interfaces):
    """Returns the interfaces in pre-order, i.e. parents first."""
    seen = set()
    ordered = []
    def visit(interface):
      if interface.id in seen:
        return
      seen.add(interface.id)
      for parent in interface.parents:
        if IsDartCollectionType(parent.type.id):
          continue
        if self._database.HasInterface(parent.type.id):
          parent_interface = self._database.GetInterface(parent.type.id)
          visit(parent_interface)
      ordered.append(interface)

    for interface in interfaces:
      visit(interface)
    return ordered

  def IsEventTarget(self, database, interface):
    if interface.id == 'EventTarget':
      return True
    for parent in interface.parents:
      parent_name = parent.type.id
      if database.HasInterface(parent_name):
        parent_interface = database.GetInterface(parent.type.id)
        if self.IsEventTarget(database, parent_interface):
          return True
    return False

  def FixEventTargets(self, database):
    for interface in database.GetInterfaces():
      if self.IsEventTarget(database, interface):
        # Add as an attribute for easy querying in generation code.
        interface.ext_attrs['EventTarget'] = None
      elif 'EventTarget' in interface.ext_attrs:
        # Create fake EventTarget parent interface for interfaces that have
        # 'EventTarget' extended attribute.
        ast = [('Annotation', [('Id', 'WebKit')]),
               ('InterfaceType', ('ScopedName', 'EventTarget'))]
        interface.parents.append(idlnode.IDLParentInterface(ast))

  def AddMissingArguments(self, database):
    ARG = idlnode.IDLArgument([('Type', ('ScopedName', 'object')), ('Id', 'arg')])
    for interface in database.GetInterfaces():
      for operation in interface.operations:
        call_with = (operation.ext_attrs.get('CallWith', '') +
                     operation.ext_attrs.get('ConstructorCallWith', ''))
        if 'ScriptArguments' in call_with:
          operation.arguments.append(ARG)
