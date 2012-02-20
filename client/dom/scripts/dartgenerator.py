#!/usr/bin/python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""This module generates Dart APIs from the IDL database."""

import emitter
import idlnode
import logging
import multiemitter
import os
import re
import shutil
from generator import *
from systembase import *
from systemfrog import *
from systemhtml import *
from systeminterface import *

_logger = logging.getLogger('dartgenerator')

def MergeNodes(node, other):
  node.operations.extend(other.operations)
  for attribute in other.attributes:
    if not node.has_attribute(attribute):
      node.attributes.append(attribute)

  node.constants.extend(other.constants)

class DartGenerator(object):
  """Utilities to generate Dart APIs and corresponding JavaScript."""

  def __init__(self, auxiliary_dir, template_dir, base_package):
    """Constructor for the DartGenerator.

    Args:
      auxiliary_dir -- location of auxiliary handwritten classes
      template_dir -- location of template files
      base_package -- the base package name for the generated code.
    """
    self._auxiliary_dir = auxiliary_dir
    self._template_dir = template_dir
    self._base_package = base_package
    self._auxiliary_files = {}
    self._dart_templates_re = re.compile(r'[\w.:]+<([\w\.<>:]+)>')

    self._emitters = None  # set later


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

  def LoadAuxiliary(self):
    def Visitor(_, dirname, names):
      for name in names:
        if name.endswith('.dart'):
          name = name[0:-5]  # strip off ".dart"
        self._auxiliary_files[name] = os.path.join(dirname, name)
    os.path.walk(self._auxiliary_dir, Visitor, None)

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
        
        interface.javascript_binding_name = (old_name if rename_javascript_binding_names
            else new_name)
 
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

  def ConvertToDartTypes(self, database):
    """Converts all IDL types to Dart primitives or qualified types"""

    def ConvertType(interface, type_name):
      """Helper method for converting a type name to the proper
      Dart name"""
      if IsPrimitiveType(type_name):
        return ConvertPrimitiveType(type_name)

      if self._IsDartType(type_name):
        # This is for when dart qualified names are explicitly
        # defined in the IDLs. Just let them be.
        return type_name

      dart_template_match = self._dart_templates_re.match(type_name)
      if dart_template_match:
        # Dart templates
        parent_type_name = type_name[0 : dart_template_match.start(1) - 1]
        sub_type_name = dart_template_match.group(1)
        return '%s<%s>' % (ConvertType(interface, parent_type_name),
                           ConvertType(interface, sub_type_name))

      return self._StripModules(type_name)

    for interface in database.GetInterfaces():
      for idl_type in interface.all(idlnode.IDLType):
        original_type_name = idl_type.id
        idl_type.id = ConvertType(interface, idl_type.id)
        # FIXME: remember original idl types that are needed by native
        # generator. We should migrate other generators to idl registry and
        # remove this hack.
        if original_type_name != idl_type.id:
          _original_idl_types[idl_type] = original_type_name

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


  def Generate(self, database, output_dir,
               module_source_preference=[], source_filter=None,
               super_database=None, common_prefix=None, super_map={},
               html_map={}, lib_dir=None, systems=[]):
    """Generates Dart and JS files for the loaded interfaces.

    Args:
      database -- database containing interfaces to generate code for.
      output_dir -- directory to write generated files to.
      module_source_preference -- priority order list of source annotations to
        use when choosing a module name, if none specified uses the module name
        from the database.
      source_filter -- if specified, only outputs interfaces that have one of
        these source annotation and rewrites the names of superclasses not
        marked with this source to use the common prefix.
      super_database -- database containing super interfaces that the generated
        interfaces should extend.
      common_prefix -- prefix for the common library, if any.
      lib_file_path -- filename for generated .lib file, None if not required.
      lib_template -- template file in this directory for generated lib file.
    """
  
    self._emitters = multiemitter.MultiEmitter()
    self._database = database
    self._output_dir = output_dir

    self._ComputeInheritanceClosure()

    self._systems = []

    # TODO(jmesserly): only create these if needed
    if ('htmlfrog' in systems) or ('htmldartium' in systems):
      html_interface_system = HtmlInterfacesSystem(
          TemplateLoader(self._template_dir, ['html/interface', 'html', '']),
          self._database, self._emitters, self._output_dir, self)
      self._systems.append(html_interface_system)
    else:
      interface_system = InterfacesSystem(
          TemplateLoader(self._template_dir, ['dom/interface', 'dom', '']),
          self._database, self._emitters, self._output_dir)
      self._systems.append(interface_system)

    if 'native' in systems:
      native_system = NativeImplementationSystem(
          TemplateLoader(self._template_dir, ['dom/native', 'dom', '']),
          self._database, self._emitters, self._auxiliary_dir,
          self._output_dir)

      self._systems.append(native_system)

    if 'wrapping' in systems:
      wrapping_system = WrappingImplementationSystem(
          TemplateLoader(self._template_dir, ['dom/wrapping', 'dom', '']),
          self._database, self._emitters, self._output_dir)

      # Makes interface files available for listing in the library for the
      # wrapping implementation.
      wrapping_system._interface_system = interface_system
      self._systems.append(wrapping_system)

    if 'dummy' in systems:
      dummy_system = DummyImplementationSystem(
          TemplateLoader(self._template_dir, ['dom/dummy', 'dom', '']),
          self._database, self._emitters, self._output_dir)

      # Makes interface files available for listing in the library for the
      # dummy implementation.
      dummy_system._interface_system = interface_system
      self._systems.append(dummy_system)

    if 'frog' in systems:
      frog_system = FrogSystem(
          TemplateLoader(self._template_dir, ['dom/frog', 'dom', '']),
          self._database, self._emitters, self._output_dir)

      frog_system._interface_system = interface_system
      self._systems.append(frog_system)

    if 'htmlfrog' in systems:
      html_system = HtmlFrogSystem(
          TemplateLoader(self._template_dir, ['html/frog', 'html', '']),
          self._database, self._emitters, self._output_dir, self)

      html_system._interface_system = html_interface_system
      self._systems.append(html_system)

    if 'htmldartium' in systems:
      html_system = HtmlDartiumSystem(
          TemplateLoader(self._template_dir, ['html/dartium', 'html', '']),
          self._database, self._emitters, self._output_dir, self)

      html_system._interface_system = html_interface_system
      self._systems.append(html_system)

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
        for system in self._systems:
          system.ProcessCallback(interface, info)
      else:
        if 'Callback' in interface.ext_attrs:
          _logger.info('Malformed callback: %s' % interface.id)
        self._ProcessInterface(interface, super_interface,
                               source_filter, common_prefix)

    # Libraries
    if lib_dir:
      for system in self._systems:
        system.GenerateLibraries(lib_dir)

    for system in self._systems:
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


  def _ProcessInterface(self, interface, super_interface_name,
                        source_filter,
                        common_prefix):
    """."""
    _logger.info('Generating %s' % interface.id)

    generators = [system.InterfaceGenerator(interface,
                                            common_prefix,
                                            super_interface_name,
                                            source_filter)
                  for system in self._systems]
    generators = filter(None, generators)

    for generator in generators:
      generator.StartInterface()

    for const in sorted(interface.constants, ConstantOutputOrder):
      for generator in generators:
        generator.AddConstant(const)

    attributes = [attr for attr in interface.attributes
                  if not self._IsEventAttribute(interface, attr)]
    for (getter, setter) in  _PairUpAttributes(attributes):
      for generator in generators:
        generator.AddAttribute(getter, setter)

    events = set([attr for attr in interface.attributes
                  if self._IsEventAttribute(interface, attr)])

    if events:
      for generator in generators:
        generator.AddEventAttributes(events)

    # The implementation should define an indexer if the interface directly
    # extends List.
    element_type = MaybeListElementType(interface)
    if element_type:
      for generator in generators:
        generator.AddIndexer(element_type)
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
      for generator in generators:
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
        for generator in generators:
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
          for generator in generators:
            generator.AddSecondaryOperation(parent_interface, info)

    for generator in generators:
      generator.FinishInterface()
    return

  def _IsEventAttribute(self, interface, attr):
    # Remove EventListener attributes like 'onclick' when addEventListener
    # is available.
    return (attr.type.id == 'EventListener' and
        'EventTarget' in self._AllImplementedInterfaces(interface))

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


  def Flush(self):
    """Write out all pending files."""
    _logger.info('Flush...')
    self._emitters.Flush()


  def _ComputeInheritanceClosure(self):
    def Collect(interface, seen, collected):
      name = interface.id
      if '<' in name:
        # TODO(sra): Handle parameterized types.
        return
      if not name in seen:
        seen.add(name)
        collected.append(name)
        for parent in interface.parents:
          # TODO(sra): Handle parameterized types.
          if not '<' in parent.type.id:
            if self._database.HasInterface(parent.type.id):
              Collect(self._database.GetInterface(parent.type.id),
                      seen, collected)

    self._inheritance_closure = {}
    for interface in self._database.GetInterfaces():
      seen = set()
      collected = []
      Collect(interface, seen, collected)
      self._inheritance_closure[interface.id] = collected

  def _AllImplementedInterfaces(self, interface):
    """Returns a list of the names of all interfaces implemented by 'interface'.
    List includes the name of 'interface'.
    """
    return self._inheritance_closure[interface.id]

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

class TemplateLoader(object):
  """Loads template files from a path."""

  def __init__(self, root, subpaths):
    """Initializes loader.

    Args:
      root - a string, the directory under which the templates are stored.
      subpaths - a list of strings, subpaths of root in search order.
    """
    self._root = root
    self._subpaths = subpaths
    self._cache = {}

  def TryLoad(self, name):
    """Returns content of template file as a string, or None of not found."""
    if name in self._cache:
      return self._cache[name]

    for subpath in self._subpaths:
      template_file = os.path.join(self._root, subpath, name)
      if os.path.exists(template_file):
        template = ''.join(open(template_file).readlines())
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

# ------------------------------------------------------------------------------

class DummyImplementationSystem(System):
  """Generates a dummy implementation for use by the editor analysis.

  All the code comes from hand-written library files.
  """

  def __init__(self, templates, database, emitters, output_dir):
    super(DummyImplementationSystem, self).__init__(
        templates, database, emitters, output_dir)

  def InterfaceGenerator(self,
                         interface,
                         common_prefix,
                         super_interface_name,
                         source_filter):
    return DummyInterfaceGenerator(self, interface)

  def ProcessCallback(self, interface, info):
    pass

  def GenerateLibraries(self, lib_dir):
    # Library generated for implementation.
    self._GenerateLibFile(
        'dom_dummy.darttemplate',
        os.path.join(lib_dir, 'dom_dummy.dart'),
        (self._interface_system._dart_interface_file_paths +
         self._interface_system._dart_callback_file_paths +
         []
         # FIXME: Move the implementation to a separate library.
         # self._dart_wrapping_file_paths
         ))

# ------------------------------------------------------------------------------

class WrappingImplementationSystem(System):

  def __init__(self, templates, database, emitters, output_dir):
    """Prepared for generating wrapping implementation.

    - Creates emitter for JS code.
    - Creates emitter for Dart code.
    """
    super(WrappingImplementationSystem, self).__init__(
        templates, database, emitters, output_dir)
    self._dart_wrapping_file_paths = []


  def InterfaceGenerator(self,
                         interface,
                         common_prefix,
                         super_interface_name,
                         source_filter):
    """."""
    interface_name = interface.id
    dart_wrapping_file_path = self._FilePathForDartWrappingImpl(interface_name)

    self._dart_wrapping_file_paths.append(dart_wrapping_file_path)

    dart_code = self._emitters.FileEmitter(dart_wrapping_file_path)
    dart_code.Emit(self._templates.Load('wrapping_impl.darttemplate'))
    return WrappingInterfaceGenerator(interface, super_interface_name,
                                      dart_code,
                                      self._BaseDefines(interface))

  def ProcessCallback(self, interface, info):
    pass

  def GenerateLibraries(self, lib_dir):
    # Library generated for implementation.
    self._GenerateLibFile(
        'wrapping_dom.darttemplate',
        os.path.join(lib_dir, 'wrapping_dom.dart'),
        (self._interface_system._dart_interface_file_paths +
         self._interface_system._dart_callback_file_paths +
         # FIXME: Move the implementation to a separate library.
         self._dart_wrapping_file_paths
         ))


  def Finish(self):
    pass


  def _FilePathForDartWrappingImpl(self, interface_name):
    """Returns the file path of the Dart wrapping implementation."""
    return os.path.join(self._output_dir, 'src', 'wrapping',
                        '_%sWrappingImplementation.dart' % interface_name)

# ------------------------------------------------------------------------------

class DummyInterfaceGenerator(object):
  """Generates nothing."""

  def __init__(self, system, interface):
    pass

  def StartInterface(self):
    pass

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

  def AddTypedArrayConstructors(self, element_type):
    pass

  def AddOperation(self, info):
    pass

  def AddEventAttributes(self, event_attrs):
    pass

# ------------------------------------------------------------------------------

class WrappingInterfaceGenerator(object):
  """Generates Dart and JS implementation for one DOM IDL interface."""

  def __init__(self, interface, super_interface, dart_code, base_members):
    """Generates Dart and JS code for the given interface.

    Args:

      interface: an IDLInterface instance. It is assumed that all types have
          been converted to Dart types (e.g. int, String), unless they are in
          the same package as the interface.
      super_interface: A string or None, the name of the common interface that
         this interface implements, if any.
      dart_code: an Emitter for the file containing the Dart implementation
          class.
      base_members: a set of names of members defined in a base class.  This is
          used to avoid static member 'overriding' in the generated Dart code.
    """
    self._interface = interface
    self._super_interface = super_interface
    self._dart_code = dart_code
    self._base_members = base_members
    self._current_secondary_parent = None


  def StartInterface(self):
    interface = self._interface
    interface_name = interface.id

    self._class_name = self._ImplClassName(interface_name)

    base = self._BaseClassName(interface)

    (self._members_emitter,
     self._top_level_emitter) = self._dart_code.Emit(
        '\n'
        'class $CLASS extends $BASE implements $INTERFACE {\n'
        '  $CLASS() : super() {}\n'
        '\n'
        '  static create_$CLASS() native {\n'
        '    return new $CLASS();\n'
        '  }\n'
        '$!MEMBERS'
        '\n'
        '  String get typeName() { return "$INTERFACE"; }\n'
        '}\n'
        '$!TOP_LEVEL',
        CLASS=self._class_name, BASE=base, INTERFACE=interface_name)

  def _ImplClassName(self, type_name):
    return '_' + type_name + 'WrappingImplementation'

  def _BaseClassName(self, interface):
    if not interface.parents:
      return 'DOMWrapperBase'

    supertype = interface.parents[0].type.id

    # FIXME: We're currently injecting List<..> and EventTarget as
    # supertypes in dart.idl. We should annotate/preserve as
    # attributes instead.  For now, this hack lets the interfaces
    # inherit, but not the classes.
    # List methods are injected in AddIndexer.
    if IsDartListType(supertype) or IsDartCollectionType(supertype):
      return 'DOMWrapperBase'

    if supertype == 'EventTarget':
      # Most implementors of EventTarget specify the EventListener operations
      # again.  If the operations are not specified, try to inherit from the
      # EventTarget implementation.
      #
      # Applies to MessagePort.
      if not [op for op in interface.operations if op.id == 'addEventListener']:
        return self._ImplClassName(supertype)
      return 'DOMWrapperBase'

    return self._ImplClassName(supertype)

  def FinishInterface(self):
    """."""
    pass

  def AddConstant(self, constant):
    # Constants are already defined on the interface.
    pass

  def _MethodName(self, prefix, name):
    method_name = prefix + name
    if name in self._base_members:  # Avoid illegal Dart 'static override'.
      method_name = method_name + '_' + self._interface.id
    return method_name

  def AddAttribute(self, getter, setter):
    if getter:
      self._AddGetter(getter)
    if setter:
      self._AddSetter(setter)

  def _AddGetter(self, attr):
    # FIXME: Instead of injecting the interface name into the method when it is
    # also implemented in the base class, suppress the method altogether if it
    # has the same signature.  I.e., let the JS do the virtual dispatch instead.
    method_name = self._MethodName('_get_', attr.id)
    self._members_emitter.Emit(
        '\n'
        '  $TYPE get $NAME() { return $METHOD(this); }\n'
        '  static $TYPE $METHOD(var _this) native;\n',
        NAME=attr.id, TYPE=attr.type.id, METHOD=method_name)

  def _AddSetter(self, attr):
    # FIXME: See comment on getter.
    method_name = self._MethodName('_set_', attr.id)
    self._members_emitter.Emit(
        '\n'
        '  void set $NAME($TYPE value) { $METHOD(this, value); }\n'
        '  static void $METHOD(var _this, $TYPE value) native;\n',
        NAME=attr.id, TYPE=attr.type.id, METHOD=method_name)

  def AddSecondaryAttribute(self, interface, getter, setter):
    self._SecondaryContext(interface)
    self.AddAttribute(getter, setter)

  def AddSecondaryOperation(self, interface, info):
    self._SecondaryContext(interface)
    self.AddOperation(info)

  def AddEventAttributes(self, event_attrs):
    pass

  def _SecondaryContext(self, interface):
    if interface is not self._current_secondary_parent:
      self._current_secondary_parent = interface
      self._members_emitter.Emit('\n  // From $WHERE\n', WHERE=interface.id)

  def AddIndexer(self, element_type):
    """Adds all the methods required to complete implementation of List."""
    # We would like to simply inherit the implementation of everything except
    # get length(), [], and maybe []=.  It is possible to extend from a base
    # array implementation class only when there is no other implementation
    # inheritance.  There might be no implementation inheritance other than
    # DOMBaseWrapper for many classes, but there might be some where the
    # array-ness is introduced by a non-root interface:
    #
    #   interface Y extends X, List<T> ...
    #
    # In the non-root case we have to choose between:
    #
    #   class YImpl extends XImpl { add List<T> methods; }
    #
    # and
    #
    #   class YImpl extends ListBase<T> { copies of transitive XImpl methods; }
    #
    if self._HasNativeIndexGetter(self._interface):
      self._EmitNativeIndexGetter(self._interface, element_type)
    else:
      self._members_emitter.Emit(
          '\n'
          '  $TYPE operator[](int index) {\n'
          '    return item(index);\n'
          '  }\n',
          TYPE=element_type)

    if self._HasNativeIndexSetter(self._interface):
      self._EmitNativeIndexSetter(self._interface, element_type)
    else:
      self._members_emitter.Emit(
          '\n'
          '  void operator[]=(int index, $TYPE value) {\n'
          '    throw new UnsupportedOperationException("Cannot assign element of immutable List.");\n'
          '  }\n',
          TYPE=element_type)

    self._members_emitter.Emit(
        '\n'
        '  void add($TYPE value) {\n'
        '    throw new UnsupportedOperationException("Cannot add to immutable List.");\n'
        '  }\n'
        '\n'
        '  void addLast($TYPE value) {\n'
        '    throw new UnsupportedOperationException("Cannot add to immutable List.");\n'
        '  }\n'
        '\n'
        '  void addAll(Collection<$TYPE> collection) {\n'
        '    throw new UnsupportedOperationException("Cannot add to immutable List.");\n'
        '  }\n'
        '\n'
        '  void sort(int compare($TYPE a, $TYPE b)) {\n'
        '    throw new UnsupportedOperationException("Cannot sort immutable List.");\n'
        '  }\n'
        '\n'
        '  void copyFrom(List<Object> src, int srcStart, '
        'int dstStart, int count) {\n'
        '    throw new UnsupportedOperationException("This object is immutable.");\n'
        '  }\n'
        '\n'
        '  int indexOf($TYPE element, [int start = 0]) {\n'
        '    return _Lists.indexOf(this, element, start, this.length);\n'
        '  }\n'
        '\n'
        '  int lastIndexOf($TYPE element, [int start = null]) {\n'
        '    if (start === null) start = length - 1;\n'
        '    return _Lists.lastIndexOf(this, element, start);\n'
        '  }\n'
        '\n'
        '  int clear() {\n'
        '    throw new UnsupportedOperationException("Cannot clear immutable List.");\n'
        '  }\n'
        '\n'
        '  $TYPE removeLast() {\n'
        '    throw new UnsupportedOperationException("Cannot removeLast on immutable List.");\n'
        '  }\n'
        '\n'
        '  $TYPE last() {\n'
        '    return this[length - 1];\n'
        '  }\n'
        '\n'
        '  void forEach(void f($TYPE element)) {\n'
        '    _Collections.forEach(this, f);\n'
        '  }\n'
        '\n'
        '  Collection map(f($TYPE element)) {\n'
        '    return _Collections.map(this, [], f);\n'
        '  }\n'
        '\n'
        '  Collection<$TYPE> filter(bool f($TYPE element)) {\n'
        '    return _Collections.filter(this, new List<$TYPE>(), f);\n'
        '  }\n'
        '\n'
        '  bool every(bool f($TYPE element)) {\n'
        '    return _Collections.every(this, f);\n'
        '  }\n'
        '\n'
        '  bool some(bool f($TYPE element)) {\n'
        '    return _Collections.some(this, f);\n'
        '  }\n'
        '\n'
        '  void setRange(int start, int length, List<$TYPE> from, [int startFrom]) {\n'
        '    throw new UnsupportedOperationException("Cannot setRange on immutable List.");\n'
        '  }\n'
        '\n'
        '  void removeRange(int start, int length) {\n'
        '    throw new UnsupportedOperationException("Cannot removeRange on immutable List.");\n'
        '  }\n'
        '\n'
        '  void insertRange(int start, int length, [$TYPE initialValue]) {\n'
        '    throw new UnsupportedOperationException("Cannot insertRange on immutable List.");\n'
        '  }\n'
        '\n'
        '  List<$TYPE> getRange(int start, int length) {\n'
        '    throw new NotImplementedException();\n'
        '  }\n'
        '\n'
        '  bool isEmpty() {\n'
        '    return length == 0;\n'
        '  }\n'
        '\n'
        '  Iterator<$TYPE> iterator() {\n'
        '    return new _FixedSizeListIterator<$TYPE>(this);\n'
        '  }\n',
        TYPE=element_type)

  def _HasNativeIndexGetter(self, interface):
    return ('IndexedGetter' in interface.ext_attrs or
            'NumericIndexedGetter' in interface.ext_attrs)

  def _EmitNativeIndexGetter(self, interface, element_type):
    method_name = '_index'
    self._members_emitter.Emit(
        '\n'
        '  $TYPE operator[](int index) { return $METHOD(this, index); }\n'
        '  static $TYPE $METHOD(var _this, int index) native;\n',
        TYPE=element_type, METHOD=method_name)

  def _HasNativeIndexSetter(self, interface):
    return 'CustomIndexedSetter' in interface.ext_attrs

  def _EmitNativeIndexSetter(self, interface, element_type):
    method_name = '_set_index'
    self._members_emitter.Emit(
        '\n'
        '  void operator[]=(int index, $TYPE value) {\n'
        '    return $METHOD(this, index, value);\n'
        '  }\n'
        '  static $METHOD(_this, index, value) native;\n',
        TYPE=element_type, METHOD=method_name)

  def AddOperation(self, info):
    """
    Arguments:
      info: An OperationInfo object.
    """
    body = self._members_emitter.Emit(
        '\n'
        '  $TYPE $NAME($PARAMS) {\n'
        '$!BODY'
        '  }\n',
        TYPE=info.type_name,
        NAME=info.name,
        PARAMS=info.ParametersImplementationDeclaration())

    # Process in order of ascending number of arguments to ensure missing
    # optional arguments are processed early.
    overloads = sorted(info.overloads,
                       key=lambda overload: len(overload.arguments))
    self._native_version = 0
    fallthrough = self.GenerateDispatch(body, info, '    ', 0, overloads)
    if fallthrough:
      body.Emit('    throw "Incorrect number or type of arguments";\n');

  def GenerateSingleOperation(self,  emitter, info, indent, operation):
    """Generates a call to a single operation.

    Arguments:
      emitter: an Emitter for the body of a block of code.
      info: the compound information about the operation and its overloads.
      indent: an indentation string for generated code.
      operation: the IDLOperation to call.
    """
    # TODO(sra): Do we need to distinguish calling with missing optional
    # arguments from passing 'null' which is represented as 'undefined'?
    def UnwrapArgExpression(name, type):
      # TODO: Type specific unwrapping.
      return '__dom_unwrap(%s)' % (name)

    def ArgNameAndUnwrapper(arg_info, overload_arg):
      (name, type, value) = arg_info
      return (name, UnwrapArgExpression(name, type))

    names_and_unwrappers = [ArgNameAndUnwrapper(info.arg_infos[i], arg)
                            for (i, arg) in enumerate(operation.arguments)]
    unwrap_args = [unwrap_arg for (_, unwrap_arg) in names_and_unwrappers]
    arg_names = [name for (name, _) in names_and_unwrappers]

    self._native_version += 1
    native_name = self._MethodName('_', info.name)
    if self._native_version > 1:
      native_name = '%s_%s' % (native_name, self._native_version)

    argument_expressions = ', '.join(['this'] + arg_names)
    if info.type_name != 'void':
      emitter.Emit('$(INDENT)return $NATIVENAME($ARGS);\n',
                   INDENT=indent,
                   NATIVENAME=native_name,
                   ARGS=argument_expressions)
    else:
      emitter.Emit('$(INDENT)$NATIVENAME($ARGS);\n'
                   '$(INDENT)return;\n',
                   INDENT=indent,
                   NATIVENAME=native_name,
                   ARGS=argument_expressions)

    self._members_emitter.Emit('  static $TYPE $NAME($PARAMS) native;\n',
                               NAME=native_name,
                               TYPE=info.type_name,
                               PARAMS=', '.join(['receiver'] + arg_names) )


  def GenerateDispatch(self, emitter, info, indent, position, overloads):
    """Generates a dispatch to one of the overloads.

    Arguments:
      emitter: an Emitter for the body of a block of code.
      info: the compound information about the operation and its overloads.
      indent: an indentation string for generated code.
      position: the index of the parameter to dispatch on.
      overloads: a list of the remaining IDLOperations to dispatch.

    Returns True if the dispatch can fall through on failure, False if the code
    always dispatches.
    """

    def NullCheck(name):
      return '%s === null' % name

    def TypeCheck(name, type):
      return '%s is %s' % (name, type)

    if position == len(info.arg_infos):
      if len(overloads) > 1:
        raise Exception('Duplicate operations ' + str(overloads))
      operation = overloads[0]
      self.GenerateSingleOperation(emitter, info, indent, operation)
      return False

    # FIXME: Consider a simpler dispatch that iterates over the
    # overloads and generates an overload specific check.  Revisit
    # when we move to named optional arguments.

    # Partition the overloads to divide and conquer on the dispatch.
    positive = []
    negative = []
    first_overload = overloads[0]
    (param_name, param_type, param_default) = info.arg_infos[position]

    if position < len(first_overload.arguments):
      # FIXME: This will not work if the second overload has a more
      # precise type than the first.  E.g.,
      # void foo(Node x);
      # void foo(Element x);
      type = first_overload.arguments[position].type.id
      test = TypeCheck(param_name, type)
      pred = lambda op: len(op.arguments) > position and op.arguments[position].type.id == type
    else:
      type = None
      test = NullCheck(param_name)
      pred = lambda op: position >= len(op.arguments)

    for overload in overloads:
      if pred(overload):
        positive.append(overload)
      else:
        negative.append(overload)

    if positive and negative:
      (true_code, false_code) = emitter.Emit(
          '$(INDENT)if ($COND) {\n'
          '$!TRUE'
          '$(INDENT)} else {\n'
          '$!FALSE'
          '$(INDENT)}\n',
          COND=test, INDENT=indent)
      fallthrough1 = self.GenerateDispatch(
          true_code, info, indent + '  ', position + 1, positive)
      fallthrough2 = self.GenerateDispatch(
          false_code, info, indent + '  ', position, negative)
      return fallthrough1 or fallthrough2

    if negative:
      raise Exception('Internal error, must be all positive')

    # All overloads require the same test.  Do we bother?

    # If the test is the same as the method's formal parameter then checked mode
    # will have done the test already. (It could be null too but we ignore that
    # case since all the overload behave the same and we don't know which types
    # in the IDL are not nullable.)
    if type == param_type:
      return self.GenerateDispatch(
          emitter, info, indent, position + 1, positive)

    # Otherwise the overloads have the same type but the type is a substype of
    # the method's synthesized formal parameter. e.g we have overloads f(X) and
    # f(Y), implemented by the synthesized method f(Z) where X<Z and Y<Z. The
    # dispatch has removed f(X), leaving only f(Y), but there is no guarantee
    # that Y = Z-X, so we need to check for Y.
    true_code = emitter.Emit(
        '$(INDENT)if ($COND) {\n'
        '$!TRUE'
        '$(INDENT)}\n',
        COND=test, INDENT=indent)
    self.GenerateDispatch(
        true_code, info, indent + '  ', position + 1, positive)
    return True

# ------------------------------------------------------------------------------

class IDLTypeInfo(object):
  def __init__(self, idl_type, native_type=None, ref_counted=True,
               has_dart_wrapper=True, conversion_template=None,
               custom_to_dart=False):
    self._idl_type = idl_type
    self._native_type = native_type
    self._ref_counted = ref_counted
    self._has_dart_wrapper = has_dart_wrapper
    self._conversion_template = conversion_template
    self._custom_to_dart = custom_to_dart

  def idl_type(self):
    return self._idl_type

  def native_type(self):
    if self._native_type:
      return self._native_type
    return self._idl_type

  def parameter_adapter_info(self):
    native_type = self.native_type()
    if self._ref_counted:
      native_type = 'RefPtr< %s >' % native_type
    if self._has_dart_wrapper:
      wrapper_type = 'Dart%s' % self.idl_type()
      adapter_type = 'ParameterAdapter<%s, %s>' % (native_type, wrapper_type)
      return (adapter_type, wrapper_type)
    return ('ParameterAdapter< %s >' % native_type, self._idl_type)

  def parameter_type(self):
    return '%s*' % self.native_type()

  def webcore_include(self):
    if self._idl_type == 'SVGNumber' or self._idl_type == 'SVGPoint':
      return None
    if self._idl_type.startswith('SVGPathSeg'):
      return self._idl_type.replace('Abs', '').replace('Rel', '')
    return self._idl_type

  def receiver(self):
    return 'receiver->'

  def conversion_include(self):
    return 'Dart%s' % self._idl_type

  def conversion_cast(self, expression):
    if self._conversion_template:
      return self._conversion_template % expression
    return expression

  def custom_to_dart(self):
    return self._custom_to_dart

class PrimitiveIDLTypeInfo(IDLTypeInfo):
  def __init__(self, idl_type, native_type=None, ref_counted=False,
               conversion_template=None,
               webcore_getter_name='getAttribute',
               webcore_setter_name='setAttribute'):
    super(PrimitiveIDLTypeInfo, self).__init__(idl_type,
        native_type=native_type, ref_counted=ref_counted,
        conversion_template=conversion_template)
    self._webcore_getter_name = webcore_getter_name
    self._webcore_setter_name = webcore_setter_name

  def parameter_adapter_info(self):
    native_type = self.native_type()
    if self._ref_counted:
      native_type = 'RefPtr< %s >' % native_type
    return ('ParameterAdapter< %s >' % native_type, None)

  def parameter_type(self):
    if self.native_type() == 'String':
      return 'const String&'
    return self.native_type()

  def conversion_include(self):
    return None

  def webcore_getter_name(self):
    return self._webcore_getter_name

  def webcore_setter_name(self):
    return self._webcore_setter_name

class SVGTearOffIDLTypeInfo(IDLTypeInfo):
  def __init__(self, idl_type, native_type='', ref_counted=True):
    super(SVGTearOffIDLTypeInfo, self).__init__(idl_type,
                                                native_type=native_type,
                                                ref_counted=ref_counted)

  def native_type(self):
    if self._native_type:
      return self._native_type
    tear_off_type = 'SVGPropertyTearOff'
    if self._idl_type.endswith('List'):
      tear_off_type = 'SVGListPropertyTearOff'
    return '%s<%s>' % (tear_off_type, self._idl_type)

  def receiver(self):
    if self._idl_type.endswith('List'):
      return 'receiver->'
    return 'receiver->propertyReference().'


_idl_type_registry = {
     # There is GC3Dboolean which is not a bool, but unsigned char for OpenGL compatibility.
    'boolean': PrimitiveIDLTypeInfo('boolean', native_type='bool',
                                    conversion_template='static_cast<bool>(%s)',
                                    webcore_getter_name='hasAttribute',
                                    webcore_setter_name='setBooleanAttribute'),
    # Some IDL's unsigned shorts/shorts are mapped to WebCore C++ enums, so we
    # use a static_cast<int> here not to provide overloads for all enums.
    'short': PrimitiveIDLTypeInfo('short', native_type='int', conversion_template='static_cast<int>(%s)'),
    'unsigned short': PrimitiveIDLTypeInfo('unsigned short', native_type='int', conversion_template='static_cast<int>(%s)'),
    'int': PrimitiveIDLTypeInfo('int'),
    'unsigned int': PrimitiveIDLTypeInfo('unsigned int', native_type='unsigned'),
    'long': PrimitiveIDLTypeInfo('long', native_type='int',
        webcore_getter_name='getIntegralAttribute',
        webcore_setter_name='setIntegralAttribute'),
    'unsigned long': PrimitiveIDLTypeInfo('unsigned long', native_type='unsigned',
        webcore_getter_name='getUnsignedIntegralAttribute',
        webcore_setter_name='setUnsignedIntegralAttribute'),
    'long long': PrimitiveIDLTypeInfo('long long'),
    'unsigned long long': PrimitiveIDLTypeInfo('unsigned long long'),
    'double': PrimitiveIDLTypeInfo('double'),

    'Date': PrimitiveIDLTypeInfo('Date',  native_type='double'),
    'DOMString': PrimitiveIDLTypeInfo('DOMString',  native_type='String'),
    'DOMTimeStamp': PrimitiveIDLTypeInfo('DOMTimeStamp'),
    'object': PrimitiveIDLTypeInfo('object',  native_type='ScriptValue'),
    'SerializedScriptValue': PrimitiveIDLTypeInfo('SerializedScriptValue', ref_counted=True),

    'DOMException': IDLTypeInfo('DOMCoreException'),
    'DOMWindow': IDLTypeInfo('DOMWindow', custom_to_dart=True),
    'Element': IDLTypeInfo('Element', custom_to_dart=True),
    'EventListener': IDLTypeInfo('EventListener', has_dart_wrapper=False),
    'EventTarget': IDLTypeInfo('EventTarget', has_dart_wrapper=False),
    'HTMLElement': IDLTypeInfo('HTMLElement', custom_to_dart=True),
    'MediaQueryListListener': IDLTypeInfo('MediaQueryListListener', has_dart_wrapper=False),
    'OptionsObject': IDLTypeInfo('OptionsObject', has_dart_wrapper=False),
    'SVGElement': IDLTypeInfo('SVGElement', custom_to_dart=True),

    'SVGAngle': SVGTearOffIDLTypeInfo('SVGAngle'),
    'SVGLength': SVGTearOffIDLTypeInfo('SVGLength'),
    'SVGLengthList': SVGTearOffIDLTypeInfo('SVGLengthList', ref_counted=False),
    'SVGMatrix': SVGTearOffIDLTypeInfo('SVGMatrix'),
    'SVGNumber': SVGTearOffIDLTypeInfo('SVGNumber', native_type='SVGPropertyTearOff<float>'),
    'SVGNumberList': SVGTearOffIDLTypeInfo('SVGNumberList', ref_counted=False),
    'SVGPathSegList': SVGTearOffIDLTypeInfo('SVGPathSegList', native_type='SVGPathSegListPropertyTearOff', ref_counted=False),
    'SVGPoint': SVGTearOffIDLTypeInfo('SVGPoint', native_type='SVGPropertyTearOff<FloatPoint>'),
    'SVGPointList': SVGTearOffIDLTypeInfo('SVGPointList', ref_counted=False),
    'SVGPreserveAspectRatio': SVGTearOffIDLTypeInfo('SVGPreserveAspectRatio'),
    'SVGRect': SVGTearOffIDLTypeInfo('SVGRect', native_type='SVGPropertyTearOff<FloatRect>'),
    'SVGStringList': SVGTearOffIDLTypeInfo('SVGStringList', native_type='SVGStaticListPropertyTearOff<SVGStringList>', ref_counted=False),
    'SVGTransform': SVGTearOffIDLTypeInfo('SVGTransform'),
    'SVGTransformList': SVGTearOffIDLTypeInfo('SVGTransformList', native_type='SVGTransformListPropertyTearOff', ref_counted=False)
}

_original_idl_types = {
}

def GetIDLTypeInfo(idl_type):
  idl_type_name = _original_idl_types.get(idl_type, idl_type.id)
  return GetIDLTypeInfoByName(idl_type_name)

def GetIDLTypeInfoByName(idl_type_name):
  return _idl_type_registry.get(idl_type_name, IDLTypeInfo(idl_type_name))

class NativeImplementationSystem(System):

  def __init__(self, templates, database, emitters, auxiliary_dir, output_dir):
    super(NativeImplementationSystem, self).__init__(
        templates, database, emitters, output_dir)

    self._auxiliary_dir = auxiliary_dir
    self._dom_public_files = []
    self._dom_impl_files = []
    self._cpp_header_files = []
    self._cpp_impl_files = []

  def InterfaceGenerator(self,
                         interface,
                         common_prefix,
                         super_interface_name,
                         source_filter):
    interface_name = interface.id

    dart_interface_path = self._FilePathForDartInterface(interface_name)
    self._dom_public_files.append(dart_interface_path)

    pure_interfaces = set([
        'ElementTimeControl',
        'ElementTraversal',
        'MediaQueryListListener',
        'NodeSelector',
        'SVGExternalResourcesRequired',
        'SVGFilterPrimitiveStandardAttributes',
        'SVGFitToViewBox',
        'SVGLangSpace',
        'SVGLocatable',
        'SVGStylable',
        'SVGTests',
        'SVGTransformable',
        'SVGURIReference',
        'SVGViewSpec',
        'SVGZoomAndPan'])
    if interface_name in pure_interfaces:
      return None

    dart_impl_path = self._FilePathForDartImplementation(interface_name)
    self._dom_impl_files.append(dart_impl_path)

    cpp_header_path = self._FilePathForCppHeader(interface_name)
    self._cpp_header_files.append(cpp_header_path)

    cpp_impl_path = self._FilePathForCppImplementation(interface_name)
    self._cpp_impl_files.append(cpp_impl_path)

    return NativeImplementationGenerator(interface, super_interface_name,
        self._emitters.FileEmitter(dart_impl_path),
        self._emitters.FileEmitter(cpp_header_path),
        self._emitters.FileEmitter(cpp_impl_path),
        self._BaseDefines(interface),
        self._templates)

  def ProcessCallback(self, interface, info):
    self._interface = interface

    dart_interface_path = self._FilePathForDartInterface(self._interface.id)
    self._dom_public_files.append(dart_interface_path)

    cpp_header_handlers_emitter = emitter.Emitter()
    cpp_impl_handlers_emitter = emitter.Emitter()
    class_name = 'Dart%s' % self._interface.id
    for operation in interface.operations:
      if operation.type.id == 'void':
        return_type = 'void'
        return_prefix = ''
      else:
        return_type = 'bool'
        return_prefix = 'return '

      parameters = []
      arguments = []
      for argument in operation.arguments:
        argument_type_info = GetIDLTypeInfo(argument.type)
        parameters.append('%s %s' % (argument_type_info.parameter_type(),
                                     argument.id))
        arguments.append(argument.id)

      cpp_header_handlers_emitter.Emit(
          '\n'
          '    virtual $TYPE handleEvent($PARAMETERS);\n',
          TYPE=return_type, PARAMETERS=', '.join(parameters))

      cpp_impl_handlers_emitter.Emit(
          '\n'
          '$TYPE $CLASS_NAME::handleEvent($PARAMETERS)\n'
          '{\n'
          '    $(RETURN_PREFIX)m_callback.handleEvent($ARGUMENTS);\n'
          '}\n',
          TYPE=return_type,
          CLASS_NAME=class_name,
          PARAMETERS=', '.join(parameters),
          RETURN_PREFIX=return_prefix,
          ARGUMENTS=', '.join(arguments))

    cpp_header_path = self._FilePathForCppHeader(self._interface.id)
    cpp_header_emitter = self._emitters.FileEmitter(cpp_header_path)
    cpp_header_emitter.Emit(
        self._templates.Load('cpp_callback_header.template'),
        INTERFACE=self._interface.id,
        HANDLERS=cpp_header_handlers_emitter.Fragments())

    cpp_impl_path = self._FilePathForCppImplementation(self._interface.id)
    self._cpp_impl_files.append(cpp_impl_path)
    cpp_impl_emitter = self._emitters.FileEmitter(cpp_impl_path)
    cpp_impl_emitter.Emit(
        self._templates.Load('cpp_callback_implementation.template'),
        INTERFACE=self._interface.id,
        HANDLERS=cpp_impl_handlers_emitter.Fragments())

  def GenerateLibraries(self, lib_dir):
    auxiliary_dir = os.path.relpath(self._auxiliary_dir, self._output_dir)

    # Generate dom_public.dart.
    self._GenerateLibFile(
        'dom_public.darttemplate',
        os.path.join(self._output_dir, 'dom_public.dart'),
        self._dom_public_files,
        AUXILIARY_DIR=auxiliary_dir);

    # Generate dom_impl.dart.
    self._GenerateLibFile(
        'dom_impl.darttemplate',
        os.path.join(self._output_dir, 'dom_impl.dart'),
        self._dom_impl_files,
        AUXILIARY_DIR=auxiliary_dir);

    # Generate DartDerivedSourcesAll.cpp.
    cpp_all_in_one_path = os.path.join(self._output_dir,
        'DartDerivedSourcesAll.cpp')

    includes_emitter = emitter.Emitter()
    for f in self._cpp_impl_files:
        path = os.path.relpath(f, os.path.dirname(cpp_all_in_one_path))
        includes_emitter.Emit('#include "$PATH"\n', PATH=path)

    cpp_all_in_one_emitter = self._emitters.FileEmitter(cpp_all_in_one_path)
    cpp_all_in_one_emitter.Emit(
        self._templates.Load('cpp_all_in_one.template'),
        INCLUDES=includes_emitter.Fragments())

    # Generate DartResolver.cpp.
    cpp_resolver_path = os.path.join(self._output_dir, 'DartResolver.cpp')

    includes_emitter = emitter.Emitter()
    resolver_body_emitter = emitter.Emitter()
    for f in self._cpp_header_files:
      path = os.path.relpath(f, os.path.dirname(cpp_resolver_path))
      includes_emitter.Emit('#include "$PATH"\n', PATH=path)
      resolver_body_emitter.Emit(
          '    if (Dart_NativeFunction func = $CLASS_NAME::resolver(name, argumentCount))\n'
          '        return func;\n',
          CLASS_NAME=os.path.splitext(os.path.basename(path))[0])

    cpp_resolver_emitter = self._emitters.FileEmitter(cpp_resolver_path)
    cpp_resolver_emitter.Emit(
        self._templates.Load('cpp_resolver.template'),
        INCLUDES=includes_emitter.Fragments(),
        RESOLVER_BODY=resolver_body_emitter.Fragments())

    # Generate DartDerivedSourcesAll.cpp
    cpp_all_in_one_path = os.path.join(self._output_dir,
        'DartDerivedSourcesAll.cpp')

    includes_emitter = emitter.Emitter()
    for file in self._cpp_impl_files:
        path = os.path.relpath(file, os.path.dirname(cpp_all_in_one_path))
        includes_emitter.Emit('#include "$PATH"\n', PATH=path)

    cpp_all_in_one_emitter = self._emitters.FileEmitter(cpp_all_in_one_path)
    cpp_all_in_one_emitter.Emit(
        self._templates.Load('cpp_all_in_one.template'),
        INCLUDES=includes_emitter.Fragments())

    # Generate DartResolver.cpp
    cpp_resolver_path = os.path.join(self._output_dir, 'DartResolver.cpp')

    includes_emitter = emitter.Emitter()
    resolver_body_emitter = emitter.Emitter()
    for file in self._cpp_header_files:
        path = os.path.relpath(file, os.path.dirname(cpp_resolver_path))
        includes_emitter.Emit('#include "$PATH"\n', PATH=path)
        resolver_body_emitter.Emit(
            '    if (Dart_NativeFunction func = $CLASS_NAME::resolver(name, argumentCount))\n'
            '        return func;\n',
            CLASS_NAME=os.path.splitext(os.path.basename(path))[0])

    cpp_resolver_emitter = self._emitters.FileEmitter(cpp_resolver_path)
    cpp_resolver_emitter.Emit(
        self._templates.Load('cpp_resolver.template'),
        INCLUDES=includes_emitter.Fragments(),
        RESOLVER_BODY=resolver_body_emitter.Fragments())

  def Finish(self):
    pass

  def _FilePathForDartInterface(self, interface_name):
    return os.path.join(self._output_dir, 'src', 'interface',
                        '%s.dart' % interface_name)

  def _FilePathForDartImplementation(self, interface_name):
    return os.path.join(self._output_dir, 'dart',
                        '%sImplementation.dart' % interface_name)

  def _FilePathForCppHeader(self, interface_name):
    return os.path.join(self._output_dir, 'cpp', 'Dart%s.h' % interface_name)

  def _FilePathForCppImplementation(self, interface_name):
    return os.path.join(self._output_dir, 'cpp', 'Dart%s.cpp' % interface_name)


class NativeImplementationGenerator(WrappingInterfaceGenerator):
  """Generates Dart implementation for one DOM IDL interface."""

  def __init__(self, interface, super_interface,
               dart_impl_emitter, cpp_header_emitter, cpp_impl_emitter,
               base_members, templates):
    """Generates Dart and C++ code for the given interface.

    Args:

      interface: an IDLInterface instance. It is assumed that all types have
          been converted to Dart types (e.g. int, String), unless they are in
          the same package as the interface.
      super_interface: A string or None, the name of the common interface that
         this interface implements, if any.
      dart_impl_emitter: an Emitter for the file containing the Dart
         implementation class.
      cpp_header_emitter: an Emitter for the file containing the C++ header.
      cpp_impl_emitter: an Emitter for the file containing the C++
         implementation.
      base_members: a set of names of members defined in a base class.  This is
          used to avoid static member 'overriding' in the generated Dart code.
    """
    self._interface = interface
    self._super_interface = super_interface
    self._dart_impl_emitter = dart_impl_emitter
    self._cpp_header_emitter = cpp_header_emitter
    self._cpp_impl_emitter = cpp_impl_emitter
    self._base_members = base_members
    self._templates = templates
    self._current_secondary_parent = None

  def StartInterface(self):
    self._class_name = self._ImplClassName(self._interface.id)
    self._interface_type_info = GetIDLTypeInfoByName(self._interface.id)
    self._members_emitter = emitter.Emitter()
    self._cpp_declarations_emitter = emitter.Emitter()
    self._cpp_impl_includes = {}
    self._cpp_definitions_emitter = emitter.Emitter()
    self._cpp_resolver_emitter = emitter.Emitter()

    self._GenerateConstructors()

  def _GenerateConstructors(self):
    # WebKit IDLs may define constructors with arguments.  Currently this form is not supported
    # (see b/1721).  There is custom implementation for some of them, the rest are just ignored
    # for now.
    SUPPORTED_CONSTRUCTORS_WITH_ARGS = [ 'WebKitCSSMatrix' ]
    UNSUPPORTED_CONSTRUCTORS_WITH_ARGS = [
        'EventSource',
        'MediaStream',
        'PeerConnection',
        'ShadowRoot',
        'SharedWorker',
        'TextTrackCue',
        'Worker' ]
    if not self._IsConstructable() or self._interface.id in UNSUPPORTED_CONSTRUCTORS_WITH_ARGS:
      return

    # TODO(antonm): currently we don't have information about number of arguments expected by
    # the constructor, so name only dispatch.
    self._cpp_resolver_emitter.Emit(
        '    if (name == "$(INTERFACE_NAME)_constructor_Callback")\n'
        '        return Dart$(INTERFACE_NAME)Internal::constructorCallback;\n',
        INTERFACE_NAME=self._interface.id)


    if self._interface.id in SUPPORTED_CONSTRUCTORS_WITH_ARGS or 'Constructor' not in self._interface.ext_attrs:
      # We have a custom implementation for it.
      self._cpp_declarations_emitter.Emit(
          '\n'
          'void constructorCallback(Dart_NativeArguments);\n')
      return

    raises_dom_exceptions = 'ConstructorRaisesException' in self._interface.ext_attrs
    raises_dart_exceptions = raises_dom_exceptions
    type_info = GetIDLTypeInfo(self._interface)
    arguments = []
    parameter_definitions = ''
    if 'CallWith' in self._interface.ext_attrs:
      call_with = self._interface.ext_attrs['CallWith']
      if call_with == 'ScriptExecutionContext':
        raises_dart_exceptions = True
        parameter_definitions = (
            '        ScriptExecutionContext* context = DartUtilities::scriptExecutionContext();\n'
            '        if (!context) {\n'
            '            exception = Dart_NewString("Failed to create an object");\n'
            '            goto fail;\n'
            '        }\n')
        arguments = ['context']
      else:
        raise Exception('Unsupported CallWith=%s attribute' % call_with)

    self._GenerateNativeCallback(
        callback_name='constructorCallback',
        idl_node=self._interface,
        parameter_definitions=parameter_definitions,
        needs_receiver=False, function_name='%s::create' % type_info.native_type(),
        arguments=arguments,
        idl_return_type=self._interface,
        raises_dart_exceptions=raises_dart_exceptions,
        raises_dom_exceptions=raises_dom_exceptions)


  def _ImplClassName(self, interface_name):
    return interface_name + 'Implementation'

  def _IsConstructable(self):
    # FIXME: support ConstructorTemplate.
    return set(['CustomConstructor', 'V8CustomConstructor', 'Constructor']) & set(self._interface.ext_attrs)

  def FinishInterface(self):
    base = self._BaseClassName(self._interface)
    self._dart_impl_emitter.Emit(
        self._templates.Load('dart_implementation.darttemplate'),
        CLASS=self._class_name, BASE=base, INTERFACE=self._interface.id,
        MEMBERS=self._members_emitter.Fragments())

    self._GenerateCppHeader()

    self._cpp_impl_emitter.Emit(
        self._templates.Load('cpp_implementation.template'),
        INTERFACE=self._interface.id,
        INCLUDES=''.join(['#include "%s.h"\n' %
          k for k in self._cpp_impl_includes.keys()]),
        CALLBACKS=self._cpp_definitions_emitter.Fragments(),
        RESOLVER=self._cpp_resolver_emitter.Fragments())

  def _GenerateCppHeader(self):
    webcore_include = self._interface_type_info.webcore_include()
    if webcore_include:
      webcore_include = '#include "%s.h"\n' % webcore_include
    else:
      webcore_include = ''

    if ('CustomToJS' in self._interface.ext_attrs or
        'CustomToJSObject' in self._interface.ext_attrs or
        'PureInterface' in self._interface.ext_attrs or
        'CPPPureInterface' in self._interface.ext_attrs or
        self._interface_type_info.custom_to_dart()):
      to_dart_value_template = (
          'Dart_Handle toDartValue($(WEBCORE_CLASS_NAME)* value);\n')
    else:
      to_dart_value_template = (
          'inline Dart_Handle toDartValue($(WEBCORE_CLASS_NAME)* value)\n'
          '{\n'
          '    return DartDOMWrapper::toDart<Dart$(INTERFACE)>(value);\n'
          '}\n')
    to_dart_value_emitter = emitter.Emitter()
    to_dart_value_emitter.Emit(
        to_dart_value_template,
        INTERFACE=self._interface.id,
        WEBCORE_CLASS_NAME=self._interface_type_info.native_type())

    self._cpp_header_emitter.Emit(
        self._templates.Load('cpp_header.template'),
        INTERFACE=self._interface.id,
        WEBCORE_INCLUDE=webcore_include,
        ADDITIONAL_INCLUDES='',
        WEBCORE_CLASS_NAME=self._interface_type_info.native_type(),
        TO_DART_VALUE=to_dart_value_emitter.Fragments(),
        DECLARATIONS=self._cpp_declarations_emitter.Fragments())

  def AddAttribute(self, getter, setter):
    # FIXME: Dartium does not support attribute event listeners. However, JS
    # implementation falls back to them when addEventListener is not available.
    # Make sure addEventListener is available in all EventTargets and remove
    # this check.
    if (getter or setter).type.id == 'EventListener':
      return

    # FIXME: support 'ImplementedBy'.
    if 'ImplementedBy' in (getter or setter).ext_attrs:
      return

    # FIXME: these should go away.
    classes_with_unsupported_custom_getters = [
        'Clipboard', 'Console', 'Coordinates', 'DeviceMotionEvent',
        'DeviceOrientationEvent', 'FileReader', 'JavaScriptCallFrame',
        'HTMLInputElement', 'HTMLOptionsCollection', 'HTMLOutputElement',
        'ScriptProfileNode', 'WebKitAnimation']
    if (self._interface.id in classes_with_unsupported_custom_getters and
        getter and set(['Custom', 'CustomGetter']) & set(getter.ext_attrs)):
      return

    if getter:
      self._AddGetter(getter)
    if setter:
      self._AddSetter(setter)

  def _AddGetter(self, attr):
    dart_declaration = '%s get %s()' % (attr.type.id, attr.id)
    is_custom = 'Custom' in attr.ext_attrs or 'CustomGetter' in attr.ext_attrs
    cpp_callback_name = self._GenerateNativeBinding(attr.id, 1,
        dart_declaration, 'Getter', is_custom)
    if is_custom:
      return

    arguments = []
    if 'Reflect' in attr.ext_attrs:
      webcore_function_name = GetIDLTypeInfo(attr.type).webcore_getter_name()
      if 'URL' in attr.ext_attrs:
        if 'NonEmpty' in attr.ext_attrs:
          webcore_function_name = 'getNonEmptyURLAttribute'
        else:
          webcore_function_name = 'getURLAttribute'
      arguments.append(self._GenerateWebCoreReflectionAttributeName(attr))
    else:
      if attr.id == 'operator':
        webcore_function_name = '_operator'
      elif attr.id == 'target' and attr.type.id == 'SVGAnimatedString':
        webcore_function_name = 'svgTarget'
      else:
        webcore_function_name = re.sub(r'^(HTML|URL|JS|XML|XSLT|\w)',
                                       lambda s: s.group(1).lower(),
                                       attr.id)
        webcore_function_name = re.sub(r'^(create|exclusive)',
                                       lambda s: 'is' + s.group(1).capitalize(),
                                       webcore_function_name)
      if attr.type.id.startswith('SVGAnimated'):
        webcore_function_name += 'Animated'

    self._GenerateNativeCallback(cpp_callback_name, attr, '',
        True, webcore_function_name, arguments, idl_return_type=attr.type,
        raises_dart_exceptions=attr.get_raises,
        raises_dom_exceptions=attr.get_raises)

  def _AddSetter(self, attr):
    dart_declaration = 'void set %s(%s)' % (attr.id, attr.type.id)
    is_custom = set(['Custom', 'CustomSetter', 'V8CustomSetter']) & set(attr.ext_attrs)
    cpp_callback_name = self._GenerateNativeBinding(attr.id, 2,
        dart_declaration, 'Setter', is_custom)
    if is_custom:
      return

    arguments = []
    if 'Reflect' in attr.ext_attrs:
      webcore_function_name = GetIDLTypeInfo(attr.type).webcore_setter_name()
      arguments.append(self._GenerateWebCoreReflectionAttributeName(attr))
    else:
      webcore_function_name = re.sub(r'^(xml(?=[A-Z])|\w)',
                                     lambda s: s.group(1).upper(),
                                     attr.id)
      webcore_function_name = 'set%s' % webcore_function_name
      if attr.type.id.startswith('SVGAnimated'):
        webcore_function_name += 'Animated'

    arguments.append(attr.id)
    parameter_definitions_emitter = emitter.Emitter()
    self._GenerateParameterAdapter(parameter_definitions_emitter, attr, 0)
    parameter_definitions = parameter_definitions_emitter.Fragments()
    self._GenerateNativeCallback(cpp_callback_name, attr, parameter_definitions,
        True, webcore_function_name, arguments, idl_return_type=None,
        raises_dart_exceptions=True,
        raises_dom_exceptions=attr.set_raises)

  def _HasNativeIndexGetter(self, interface):
    return ('CustomIndexedGetter' in interface.ext_attrs or
            'NumericIndexedGetter' in interface.ext_attrs)

  def _EmitNativeIndexGetter(self, interface, element_type):
    dart_declaration = '%s operator[](int index)' % element_type
    self._GenerateNativeBinding('numericIndexGetter', 2, dart_declaration,
        'Callback', True)

  def _EmitNativeIndexSetter(self, interface, element_type):
    dart_declaration = 'void operator[]=(int index, %s value)' % element_type
    self._GenerateNativeBinding('numericIndexSetter', 3, dart_declaration,
        'Callback', True)

  def AddOperation(self, info):
    """
    Arguments:
      info: An OperationInfo object.
    """

    if 'Custom' in info.overloads[0].ext_attrs:
      parameters = info.ParametersImplementationDeclaration()
      dart_declaration = '%s %s(%s)' % (info.type_name, info.name, parameters)
      argument_count = 1 + len(info.arg_infos)
      self._GenerateNativeBinding(info.name, argument_count, dart_declaration,
          'Callback', True)
      return

    body = self._members_emitter.Emit(
        '\n'
        '  $TYPE $NAME($PARAMETERS) {\n'
        '$!BODY'
        '  }\n',
        TYPE=info.type_name,
        NAME=info.name,
        PARAMETERS=info.ParametersImplementationDeclaration())

    # Process in order of ascending number of arguments to ensure missing
    # optional arguments are processed early.
    overloads = sorted(info.overloads,
                       key=lambda overload: len(overload.arguments))
    self._native_version = 0
    fallthrough = self.GenerateDispatch(body, info, '    ', 0, overloads)
    if fallthrough:
      body.Emit('    throw "Incorrect number or type of arguments";\n');

  def GenerateSingleOperation(self,  dispatch_emitter, info, indent, operation):
    """Generates a call to a single operation.

    Arguments:
      dispatch_emitter: an dispatch_emitter for the body of a block of code.
      info: the compound information about the operation and its overloads.
      indent: an indentation string for generated code.
      operation: the IDLOperation to call.
    """

    # FIXME: support ImplementedBy callbacks.
    if 'ImplementedBy' in operation.ext_attrs:
      return

    for op in self._interface.operations:
      if op.id != operation.id or len(op.arguments) <= len(operation.arguments):
        continue
      next_argument = op.arguments[len(operation.arguments)]
      if next_argument.is_optional and 'Callback' in next_argument.ext_attrs:
        # FIXME: '[Optional, Callback]' arguments could be non-optional in
        # webcore. We need to fix overloads handling to generate native
        # callbacks properly.
        return

    self._native_version += 1
    native_name = info.name
    if self._native_version > 1:
      native_name = '%s_%s' % (native_name, self._native_version)
    argument_list = ', '.join([info.arg_infos[i][0]
                               for (i, arg) in enumerate(operation.arguments)])

    # Generate dispatcher.
    if info.type_name != 'void':
      dispatch_emitter.Emit('$(INDENT)return _$NATIVENAME($ARGS);\n',
                            INDENT=indent,
                            NATIVENAME=native_name,
                            ARGS=argument_list)
    else:
      dispatch_emitter.Emit('$(INDENT)_$NATIVENAME($ARGS);\n'
                            '$(INDENT)return;\n',
                            INDENT=indent,
                            NATIVENAME=native_name,
                            ARGS=argument_list)
    # Generate binding.
    dart_declaration = '%s _%s(%s)' % (info.type_name, native_name,
                                       argument_list)
    is_custom = 'Custom' in operation.ext_attrs
    cpp_callback_name = self._GenerateNativeBinding(
        native_name, 1 + len(operation.arguments), dart_declaration, 'Callback',
        is_custom)
    if is_custom:
      return

    # Generate callback.
    webcore_function_name = operation.id
    if 'ImplementedAs' in operation.ext_attrs:
      webcore_function_name = operation.ext_attrs['ImplementedAs']

    parameter_definitions_emitter = emitter.Emitter()
    raises_dart_exceptions = len(operation.arguments) > 0 or operation.raises
    arguments = []

    # Process 'CallWith' argument.
    if 'CallWith' in operation.ext_attrs:
      call_with = operation.ext_attrs['CallWith']
      if call_with == 'ScriptExecutionContext':
        parameter_definitions_emitter.Emit(
            '        ScriptExecutionContext* context = DartUtilities::scriptExecutionContext();\n'
            '        if (!context)\n'
            '            return;\n')
        arguments.append('context')
      elif call_with == 'ScriptArguments|CallStack':
        raises_dart_exceptions = True
        self._cpp_impl_includes['ScriptArguments'] = 1
        self._cpp_impl_includes['ScriptCallStack'] = 1
        self._cpp_impl_includes['V8Proxy'] = 1
        self._cpp_impl_includes['v8'] = 1
        parameter_definitions_emitter.Emit(
            '        v8::HandleScope handleScope;\n'
            '        v8::Context::Scope scope(V8Proxy::mainWorldContext(DartUtilities::domWindowForCurrentIsolate()->frame()));\n'
            '        Dart_Handle customArgument = Dart_GetNativeArgument(args, $INDEX);\n'
            '        RefPtr<ScriptArguments> scriptArguments(DartUtilities::createScriptArguments(customArgument, exception));\n'
            '        if (!scriptArguments)\n'
            '            goto fail;\n'
            '        RefPtr<ScriptCallStack> scriptCallStack(DartUtilities::createScriptCallStack());\n'
            '        if (!scriptCallStack->size())\n'
            '            return;\n',
            INDEX=len(operation.arguments))
        arguments.extend(['scriptArguments', 'scriptCallStack'])

    # Process Dart arguments.
    for (i, argument) in enumerate(operation.arguments):
      if i == len(operation.arguments) - 1 and self._interface.id == 'Console' and argument.id == 'arg':
        # FIXME: we are skipping last argument here because it was added in
        # supplemental dart.idl. Cleanup dart.idl and remove this check.
        break
      self._GenerateParameterAdapter(parameter_definitions_emitter, argument, i)
      arguments.append(argument.id)

    if operation.id in ['addEventListener', 'removeEventListener']:
      # addEventListener's and removeEventListener's last argument is marked
      # as optional in idl, but is not optional in webcore implementation.
      if len(operation.arguments) == 2:
        arguments.append('false')

    if self._interface.id == 'CSSStyleDeclaration' and operation.id == 'setProperty':
      # CSSStyleDeclaration.setProperty priority parameter is optional in Dart
      # idl, but is not optional in webcore implementation.
      if len(operation.arguments) == 2:
        arguments.append('String()')

    if 'NeedsUserGestureCheck' in operation.ext_attrs:
      arguments.extend('DartUtilities::processingUserGesture')

    parameter_definitions = parameter_definitions_emitter.Fragments()
    self._GenerateNativeCallback(cpp_callback_name, operation, parameter_definitions,
        True, webcore_function_name, arguments, idl_return_type=operation.type,
        raises_dart_exceptions=raises_dart_exceptions,
        raises_dom_exceptions=operation.raises)

  def _GenerateNativeCallback(self, callback_name, idl_node,
      parameter_definitions, needs_receiver, function_name, arguments, idl_return_type,
      raises_dart_exceptions, raises_dom_exceptions):
    if raises_dom_exceptions:
      arguments.append('ec')
    prefix = ''
    if needs_receiver: prefix = self._interface_type_info.receiver()
    callback = '%s%s(%s)' % (prefix, function_name, ', '.join(arguments))

    nested_templates = []
    if idl_return_type and idl_return_type.id != 'void':
      return_type_info = GetIDLTypeInfo(idl_return_type)
      conversion_cast = return_type_info.conversion_cast('$BODY')
      if isinstance(return_type_info, SVGTearOffIDLTypeInfo):
        svg_primitive_types = ['SVGAngle', 'SVGLength', 'SVGMatrix',
            'SVGNumber', 'SVGPoint', 'SVGRect', 'SVGTransform']
        conversion_cast = '%s::create($BODY)'
        if self._interface.id.startswith('SVGAnimated'):
          conversion_cast = 'static_cast<%s*>($BODY)'
        elif return_type_info.idl_type() == 'SVGStringList':
          conversion_cast = '%s::create(receiver, $BODY)'
        elif self._interface.id.endswith('List'):
          conversion_cast = 'static_cast<%s*>($BODY.get())'
        elif return_type_info.idl_type() in svg_primitive_types:
          conversion_cast = '%s::create($BODY)'
        else:
          conversion_cast = 'static_cast<%s*>($BODY)'
        conversion_cast = conversion_cast % return_type_info.native_type()
      nested_templates.append(conversion_cast)

      if return_type_info.conversion_include():
        self._cpp_impl_includes[return_type_info.conversion_include()] = 1
      if (return_type_info.idl_type() in ['DOMString', 'AtomicString'] and
          'TreatReturnedNullStringAs' in idl_node.ext_attrs):
        nested_templates.append('$BODY, ConvertDefaultToNull')
      nested_templates.append(
          '        Dart_Handle returnValue = toDartValue($BODY);\n'
          '        if (returnValue)\n'
          '            Dart_SetReturnValue(args, returnValue);\n')
    else:
      nested_templates.append('        $BODY;\n')

    if raises_dom_exceptions:
      nested_templates.append(
          '        ExceptionCode ec = 0;\n'
          '$BODY'
          '        if (UNLIKELY(ec)) {\n'
          '            exception = DartDOMWrapper::exceptionCodeToDartException(ec);\n'
          '            goto fail;\n'
          '        }\n')

    nested_templates.append(
        '    {\n'
        '$PARAMETER_DEFINITIONS'
        '$BODY'
        '        return;\n'
        '    }\n')

    if raises_dart_exceptions:
      nested_templates.append(
          '    Dart_Handle exception;\n'
          '$BODY'
          '\n'
          'fail:\n'
          '    Dart_ThrowException(exception);\n'
          '    ASSERT_NOT_REACHED();\n')

    nested_templates.append(
        '\n'
        'static void $CALLBACK_NAME(Dart_NativeArguments args)\n'
        '{\n'
        '    DartApiScope dartApiScope;\n'
        '$BODY'
        '}\n')

    template_parameters = {
        'CALLBACK_NAME': callback_name,
        'WEBCORE_CLASS_NAME': self._interface_type_info.native_type(),
        'PARAMETER_DEFINITIONS': parameter_definitions,
    }
    if needs_receiver:
      template_parameters['PARAMETER_DEFINITIONS'] = emitter.Format(
          '        $WEBCORE_CLASS_NAME* receiver = DartDOMWrapper::receiver< $WEBCORE_CLASS_NAME >(args);\n'
          '        $PARAMETER_DEFINITIONS\n',
          **template_parameters)

    for template in nested_templates:
      template_parameters['BODY'] = callback
      callback = emitter.Format(template, **template_parameters)

    self._cpp_definitions_emitter.Emit(callback)

  def _GenerateParameterAdapter(self, emitter, idl_argument, index):
    type_info = GetIDLTypeInfo(idl_argument.type)
    (adapter_type, include_name) = type_info.parameter_adapter_info()
    if include_name:
      self._cpp_impl_includes[include_name] = 1
    emitter.Emit(
        '\n'
        '        const $ADAPTER_TYPE $NAME(Dart_GetNativeArgument(args, $INDEX));\n'
        '        if (!$NAME.conversionSuccessful()) {\n'
        '            exception = $NAME.exception();\n'
        '            goto fail;\n'
        '        }\n',
        ADAPTER_TYPE=adapter_type,
        NAME=idl_argument.id,
        INDEX=index + 1)

  def _GenerateNativeBinding(self, idl_name, argument_count, dart_declaration,
      native_suffix, is_custom):
    native_binding = '%s_%s_%s' % (self._interface.id, idl_name, native_suffix)
    self._members_emitter.Emit(
        '\n'
        '  $DART_DECLARATION native "$NATIVE_BINDING";\n',
        DART_DECLARATION=dart_declaration, NATIVE_BINDING=native_binding)

    cpp_callback_name = '%s%s' % (idl_name, native_suffix)
    self._cpp_resolver_emitter.Emit(
        '    if (argumentCount == $ARGC && name == "$NATIVE_BINDING")\n'
        '        return Dart$(INTERFACE_NAME)Internal::$CPP_CALLBACK_NAME;\n',
        ARGC=argument_count,
        NATIVE_BINDING=native_binding,
        INTERFACE_NAME=self._interface.id,
        CPP_CALLBACK_NAME=cpp_callback_name)

    if is_custom:
      self._cpp_declarations_emitter.Emit(
          '\n'
          'void $CPP_CALLBACK_NAME(Dart_NativeArguments);\n',
          CPP_CALLBACK_NAME=cpp_callback_name)

    return cpp_callback_name

  def _GenerateWebCoreReflectionAttributeName(self, attr):
    namespace = 'HTMLNames'
    svg_exceptions = ['class', 'id', 'onabort', 'onclick', 'onerror', 'onload',
                      'onmousedown', 'onmousemove', 'onmouseout', 'onmouseover',
                      'onmouseup', 'onresize', 'onscroll', 'onunload']
    if self._interface.id.startswith('SVG') and not attr.id in svg_exceptions:
      namespace = 'SVGNames'
    self._cpp_impl_includes[namespace] = 1

    attribute_name = attr.ext_attrs['Reflect'] or attr.id.lower()
    return 'WebCore::%s::%sAttr' % (namespace, attribute_name)
