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
from systembase import *

_logger = logging.getLogger('dartgenerator')

def MergeNodes(node, other):
  node.operations.extend(other.operations)
  for attribute in other.attributes:
    if not node.has_attribute(attribute):
      node.attributes.append(attribute)

  node.constants.extend(other.constants)

class DartGenerator(object):
  """Utilities to generate Dart APIs and corresponding JavaScript."""

  def __init__(self):
    self._auxiliary_files = {}
    self._dart_templates_re = re.compile(r'[\w.:]+<([\w\.<>:]+)>')

  def _StripModules(self, type_name):
    return type_name.split('::')[-1]

  def _IsCompoundType(self, database, type_name):
    if IsPrimitiveType(type_name):
      return True

    striped_type_name = self._StripModules(type_name)
    if database.HasInterface(striped_type_name):
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

  def RenameTypes(self, database, conversion_table, rename_javascript_binding_names):
    """Renames interfaces using the given conversion table.

    References through all interfaces will be renamed as well.

    Args:
      database: the database to apply the renames to.
      conversion_table: maps old names to new names.
    """

    if conversion_table is None:
      conversion_table = {}

    # Rename interfaces:
    for old_name, new_name in conversion_table.items():
      if database.HasInterface(old_name):
        _logger.info('renaming interface %s to %s' % (old_name, new_name))
        interface = database.GetInterface(old_name)
        database.DeleteInterface(old_name)
        if not database.HasInterface(new_name):
          interface.id = new_name
          database.AddInterface(interface)
        else:
          new_interface = database.GetInterface(new_name)
          MergeNodes(new_interface, interface)

        if rename_javascript_binding_names:
          interface.javascript_binding_name = new_name
          interface.doc_js_name = new_name
          for member in (interface.operations + interface.constants
              + interface.attributes):
            member.doc_js_interface_name = new_name


    # Fix references:
    for interface in database.GetInterfaces():
      for idl_type in interface.all(idlnode.IDLType):
        type_name = self._StripModules(idl_type.id)
        if type_name in conversion_table:
          idl_type.id = conversion_table[type_name]

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

  def Generate(self, database, system, source_filter=None, super_database=None,
      common_prefix=None, webkit_renames={}, html_renames={}):
    self._database = database

    # Collect interfaces
    interfaces = []
    for interface in database.GetInterfaces():
      if not MatchSourceFilter(source_filter, interface):
        # Skip this interface since it's not present in the required source
        _logger.info('Omitting interface - %s' % interface.id)
        continue
      interfaces.append(interface)

    # TODO(sra): Use this list of exception names to generate information to
    # tell Frog which exceptions can be passed from JS to Dart code.
    exceptions = self._CollectExceptions(interfaces)

    super_map = dict((v, k) for k, v in webkit_renames.iteritems())

    # Render all interfaces into Dart and save them in files.
    for interface in self._PreOrderInterfaces(interfaces):

      super_interface = None
      super_name = interface.id

      if super_name in super_map:
        super_name = super_map[super_name]

      if (super_database is not None and
          super_database.HasInterface(super_name)):
        super_interface = super_name

      interface_name = interface.id
      auxiliary_file = self._auxiliary_files.get(interface_name)
      if auxiliary_file is not None:
        _logger.info('Skipping %s because %s exists' % (
            interface_name, auxiliary_file))
        continue

      info = RecognizeCallback(interface)
      if info:
       system.ProcessCallback(interface, info)
      else:
        if 'Callback' in interface.ext_attrs:
          _logger.info('Malformed callback: %s' % interface.id)
        self._ProcessInterface(system, interface, super_interface,
                               source_filter, common_prefix)

    system.GenerateLibraries()
    system.Finish()

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


  def _ProcessInterface(self, system, interface, super_interface_name,
                        source_filter,
                        common_prefix):
    """."""
    _logger.info('Generating %s' % interface.id)

    generator = system.InterfaceGenerator(interface,
                                          common_prefix,
                                          super_interface_name,
                                          source_filter)
    if not generator:
      return

    generator.StartInterface()

    for const in sorted(interface.constants, ConstantOutputOrder):
      generator.AddConstant(const)

    attributes = [attr for attr in interface.attributes
                  if attr.type.id != 'EventListener']
    for (getter, setter) in  _PairUpAttributes(attributes):
      generator.AddAttribute(getter, setter)

    # The implementation should define an indexer if the interface directly
    # extends List.
    (element_type, requires_indexer) = ListImplementationInfo(
          interface, self._database)
    if element_type:
      if requires_indexer:
        generator.AddIndexer(element_type)
      else:
        generator.AmendIndexer(element_type)
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
        generator.AddStaticOperation(info)
      else:
        generator.AddOperation(info)

    # With multiple inheritance, attributes and operations of non-first
    # interfaces need to be added.  Sometimes the attribute or operation is
    # defined in the current interface as well as a parent.  In that case we
    # avoid making a duplicate definition and pray that the signatures match.

    for parent_interface in self._TransitiveSecondaryParents(interface):
      if isinstance(parent_interface, str):  # IsDartCollectionType(parent_interface)
        continue
      attributes = [attr for attr in parent_interface.attributes
                    if not FindMatchingAttribute(interface, attr)]
      for (getter, setter) in _PairUpAttributes(attributes):
        generator.AddSecondaryAttribute(parent_interface, getter, setter)

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
          generator.AddSecondaryOperation(parent_interface, info)

    generator.FinishInterface()

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
    walk(interface.parents[1:])
    return result;


  def _CollectExceptions(self, interfaces):
    """Returns the names of all exception classes raised."""
    exceptions = set()
    for interface in interfaces:
      for attribute in interface.attributes:
        if attribute.get_raises:
          exceptions.add(attribute.get_raises.id)
        if attribute.set_raises:
          exceptions.add(attribute.set_raises.id)
      for operation in interface.operations:
        if operation.raises:
          exceptions.add(operation.raises.id)
    return exceptions


  def FixEventTargets(self, database):
    for interface in database.GetInterfaces():
      # Create fake EventTarget parent interface for interfaces that have
      # 'EventTarget' extended attribute.
      if 'EventTarget' in interface.ext_attrs:
        ast = [('Annotation', [('Id', 'WebKit')]),
               ('InterfaceType', ('ScopedName', 'EventTarget'))]
        interface.parents.append(idlnode.IDLParentInterface(ast))

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

# ------------------------------------------------------------------------------

class DummyImplementationSystem(System):
  """Generates a dummy implementation for use by the editor analysis.

  All the code comes from hand-written library files.
  """

  def __init__(self, templates, database, emitters, output_dir):
    super(DummyImplementationSystem, self).__init__(
        templates, database, emitters, output_dir)
    factory_providers_file = os.path.join(self._output_dir, 'src', 'dummy',
                                          'RegularFactoryProviders.dart')
    self._factory_providers_emitter = self._emitters.FileEmitter(
        factory_providers_file)
    self._impl_file_paths = [factory_providers_file]

  def InterfaceGenerator(self,
                         interface,
                         common_prefix,
                         super_interface_name,
                         source_filter):
    return DummyInterfaceGenerator(self, interface)

  def ProcessCallback(self, interface, info):
    pass

  def GenerateLibraries(self):
    # Library generated for implementation.
    self._GenerateLibFile(
        'dom_dummy.darttemplate',
        os.path.join(self._output_dir, 'dom_dummy.dart'),
        (self._interface_system._dart_interface_file_paths +
         self._interface_system._dart_callback_file_paths +
         self._impl_file_paths))


# ------------------------------------------------------------------------------

class DummyInterfaceGenerator(object):
  """Generates dummy implementation."""

  def __init__(self, system, interface):
    self._system = system
    self._interface = interface

  def StartInterface(self):
    # There is no implementation to match the interface, but there might be a
    # factory constructor for the Dart interface.
    constructor_info = AnalyzeConstructor(self._interface)
    if constructor_info:
      dart_interface_name = self._interface.id
      self._EmitFactoryProvider(dart_interface_name, constructor_info)

  def _EmitFactoryProvider(self, interface_name, constructor_info):
    factory_provider = '_' + interface_name + 'FactoryProvider'
    self._system._factory_providers_emitter.Emit(
        self._system._templates.Load('factoryprovider.darttemplate'),
        FACTORYPROVIDER=factory_provider,
        CONSTRUCTOR=interface_name,
        PARAMETERS=constructor_info.ParametersImplementationDeclaration())

  def FinishInterface(self):
    pass

  def AddConstant(self, constant):
    pass

  def AddAttribute(self, getter, setter):
    pass

  def AddSecondaryAttribute(self, interface, getter, setter):
    pass

  def AddSecondaryOperation(self, interface, info):
    pass

  def AddIndexer(self, element_type):
    pass

  def AmendIndexer(sefl, element_type):
    pass

  def AddTypedArrayConstructors(self, element_type):
    pass

  def AddOperation(self, info):
    pass

  def AddStaticOperation(self, info):
    pass

  def AddEventAttributes(self, event_attrs):
    pass
