#!/usr/bin/python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""This module provides base functionality for systems to generate
Dart APIs from the IDL database."""

import os
from generator import *

class System(object):
  """A System generates all the files for one implementation.

  This is a base class for all the specific systems.
  The life-cycle of a System is:
  - construction (__init__)
  - (ProcessInterface)*  # for each IDL interface
  """

  def __init__(self, options):
    self._templates = options.templates
    self._database = options.database
    self._type_registry = options.type_registry
    self._renamer = options.renamer

  def ProcessInterface(self, interface):
    """Processes an interface that is not a callback function."""
    pass

  # Helper methods used by several systems.

  def _BaseDefines(self, interface):
    """Returns a set of names (strings) for members defined in a base class.
    """
    def WalkParentChain(interface):
      if interface.parents:
        # Only consider primary parent, secondary parents are not on the
        # implementation class inheritance chain.
        parent = interface.parents[0]
        if IsDartCollectionType(parent.type.id):
          return
        if self._database.HasInterface(parent.type.id):
          parent_interface = self._database.GetInterface(parent.type.id)
          for attr in parent_interface.attributes:
            result.add(attr.id)
          for op in parent_interface.operations:
            result.add(op.id)
          WalkParentChain(parent_interface)

    result = set()
    WalkParentChain(interface)
    return result

class BaseGenerator(object):
  def __init__(self, database, type_registry, interface):
    self._database = database
    self._type_registry = type_registry
    self._interface = interface

  def Generate(self):
    if 'Callback' in self._interface.ext_attrs:
      handlers = [operation for operation in self._interface.operations
                  if operation.id == 'handleEvent']
      info = AnalyzeOperation(self._interface, handlers)
      self.GenerateCallback(info)
      return

    self.StartInterface()
    self.AddMembers(self._interface)
    self.AddSecondaryMembers(self._interface)
    self.FinishInterface()

  def GenerateCallback(self, info):
    pass

  def AddMembers(self, interface):
    for const in sorted(interface.constants, ConstantOutputOrder):
      self.AddConstant(const)

    for attr in interface.attributes:
      if attr.type.id != 'EventListener':
        self.AddAttribute(attr)

    # The implementation should define an indexer if the interface directly
    # extends List.
    (element_type, requires_indexer) = ListImplementationInfo(
          interface, self._database)
    if element_type:
      if requires_indexer:
        self.AddIndexer(element_type)
      else:
        self.AmendIndexer(element_type)
    # Group overloaded operations by id
    operationsById = {}
    for operation in interface.operations:
      if operation.id not in operationsById:
        operationsById[operation.id] = []
      operationsById[operation.id].append(operation)

    # Generate operations
    for id in sorted(operationsById.keys()):
      operations = operationsById[id]
      info = AnalyzeOperation(interface, operations)
      self.AddOperation(info)

  def AddSecondaryMembers(self, interface):
    # With multiple inheritance, attributes and operations of non-first
    # interfaces need to be added.  Sometimes the attribute or operation is
    # defined in the current interface as well as a parent.  In that case we
    # avoid making a duplicate definition and pray that the signatures match.
    secondary_parents = self._TransitiveSecondaryParents(interface)
    for parent_interface in secondary_parents:
      if isinstance(parent_interface, str):  # IsDartCollectionType(parent_interface)
        continue
      for attr in parent_interface.attributes:
        if not FindMatchingAttribute(interface, attr):
          self.AddSecondaryAttribute(parent_interface, attr)

      # Group overloaded operations by id
      operationsById = {}
      for operation in parent_interface.operations:
        if operation.id not in operationsById:
          operationsById[operation.id] = []
        operationsById[operation.id].append(operation)

      # Generate operations
      for id in sorted(operationsById.keys()):
        if not any(op.id == id for op in interface.operations):
          operations = operationsById[id]
          info = AnalyzeOperation(interface, operations)
          self.AddSecondaryOperation(parent_interface, info)

  def AddConstant(self, constant):
    pass

  def AddAttribute(self, attribute):
    pass

  def AddIndexer(self, element_type):
    pass

  def AmendIndexer(self, element_type):
    pass

  def AddOperation(self, info):
    pass

  def AddSecondaryAttribute(self, interface, attribute):
    pass

  def AddSecondaryOperation(self, interface, info):
    pass

  def _TransitiveSecondaryParents(self, interface):
    """Returns a list of all non-primary parents.

    The list contains the interface objects for interfaces defined in the
    database, and the name for undefined interfaces.
    """
    def walk(parents):
      for parent in parents:
        if IsDartCollectionType(parent.type.id):
          result.append(parent.type.id)
          continue
        if self._database.HasInterface(parent.type.id):
          parent_interface = self._database.GetInterface(parent.type.id)
          result.append(parent_interface)
          walk(parent_interface.parents)

    result = []
    if interface.parents:
      parent = interface.parents[0]
      if IsPureInterface(parent.type.id):
        walk(interface.parents)
      else:
        walk(interface.parents[1:])
    return result

  def _TypeInfo(self, type_name):
    return self._type_registry.TypeInfo(type_name)

  def _DartType(self, type_name):
    return self._type_registry.DartType(type_name)


class GeneratorOptions(object):
  def __init__(self, templates, database, type_registry, renamer):
    self.templates = templates
    self.database = database
    self.type_registry = type_registry
    self.renamer = renamer


def IsReadOnly(attribute):
  return attribute.is_read_only or 'Replaceable' in attribute.ext_attrs
