#!/usr/bin/python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""This module provides base functionality for systems to generate
Dart APIs from the IDL database."""

import os
from generator import *

def MassagePath(path):
  # The most robust way to emit path separators is to use / always.
  return path.replace('\\', '/')

class System(object):
  """A System generates all the files for one implementation.

  This is a base class for all the specific systems.
  The life-cycle of a System is:
  - construction (__init__)
  - (InterfaceGenerator | ProcessCallback)*  # for each IDL interface
  - GenerateLibraries
  - Finish
  """

  def __init__(self, templates, database, emitters, output_dir):
    self._templates = templates
    self._database = database
    self._emitters = emitters
    self._output_dir = output_dir
    self._dart_callback_file_paths = []

  def InterfaceGenerator(self,
                         interface,
                         common_prefix,
                         super_interface_name,
                         source_filter):
    """Returns an interface generator for |interface|.

    Called once for each interface that is not a callback function.
    """
    return None

  def ProcessCallback(self, interface, info):
    """Processes an interface that is a callback function."""
    pass

  def GenerateLibraries(self, lib_dir):
    pass

  def Finish(self):
    pass


  # Helper methods used by several systems.

  def _ProcessCallback(self, interface, info, file_path):
    """Generates a typedef for the callback interface."""
    self._dart_callback_file_paths.append(file_path)
    code = self._emitters.FileEmitter(file_path)

    code.Emit(self._templates.Load('callback.darttemplate'))
    code.Emit('typedef $TYPE $NAME($PARAMS);\n',
              NAME=interface.id,
              TYPE=info.type_name,
              PARAMS=info.ParametersImplementationDeclaration())


  def _GenerateLibFile(self, lib_template, lib_file_path, file_paths,
                       **template_args):
    """Generates a lib file from a template and a list of files.

    Additional keyword arguments are passed to the template.
    Typically called from self.GenerateLibraries.
    """
    # Load template.
    template = self._templates.Load(lib_template)
    # Generate the .lib file.
    lib_file_contents = self._emitters.FileEmitter(lib_file_path)

    # Emit the list of #source directives.
    list_emitter = lib_file_contents.Emit(template, **template_args)
    lib_file_dir = os.path.dirname(lib_file_path)
    for path in sorted(file_paths):
      relpath = os.path.relpath(path, lib_file_dir)
      list_emitter.Emit("#source('$PATH');\n", PATH=MassagePath(relpath))


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
    return result;

class BaseGenerator(object):
  def __init__(self, database):
    self._database = database

  def AddMembers(self, interface):
    for const in sorted(interface.constants, ConstantOutputOrder):
      self.AddConstant(const)

    attributes = [attr for attr in interface.attributes
                  if attr.type.id != 'EventListener']
    for (getter, setter) in  _PairUpAttributes(attributes):
      self.AddAttribute(getter, setter)

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
      if info.IsStatic():
        self.AddStaticOperation(info)
      else:
        self.AddOperation(info)

  def AddSecondaryMembers(self, interface, secondary_parents):
    # With multiple inheritance, attributes and operations of non-first
    # interfaces need to be added.  Sometimes the attribute or operation is
    # defined in the current interface as well as a parent.  In that case we
    # avoid making a duplicate definition and pray that the signatures match.

    for parent_interface in secondary_parents:
      if isinstance(parent_interface, str):  # IsDartCollectionType(parent_interface)
        continue
      attributes = [attr for attr in parent_interface.attributes
                    if not FindMatchingAttribute(interface, attr)]
      for (getter, setter) in _PairUpAttributes(attributes):
        self.AddSecondaryAttribute(parent_interface, getter, setter)

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

  def AddAttribute(self, getter, setter):
    pass

  def AddIndexer(self, element_type):
    pass

  def AmendIndexer(self, element_type):
    pass

  def AddOperation(self, info):
    pass

  def AddStaticOperation(self, info):
    pass

  def AddSecondaryAttribute(self, interface, getter, setter):
    pass

  def AddSecondaryOperation(self, interface, attr):
    pass


def _PairUpAttributes(attributes):
  """Returns a list of (getter, setter) pairs sorted by name.

  One element of the pair may be None.
  """
  names = sorted(set(attr.id for attr in attributes))
  getters = {}
  setters = {}
  for attr in attributes:
    if attr.is_fc_getter:
      getters[attr.id] = attr
    elif attr.is_fc_setter and 'Replaceable' not in attr.ext_attrs:
      setters[attr.id] = attr
  return [(getters.get(id), setters.get(id)) for id in names]
