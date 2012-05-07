#!/usr/bin/python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""This module providesfunctionality for systems to generate
Dart interfaces from the IDL database."""

import os
import systembase
from generator import *

class InterfacesSystem(systembase.System):

  def __init__(self, templates, database, emitters, output_dir):
    super(InterfacesSystem, self).__init__(
        templates, database, emitters, output_dir)
    self._dart_interface_file_paths = []


  def InterfaceGenerator(self,
                         interface,
                         common_prefix,
                         super_interface_name,
                         source_filter):
    """."""
    interface_name = interface.id
    dart_interface_file_path = self._FilePathForDartInterface(interface_name)

    self._dart_interface_file_paths.append(dart_interface_file_path)

    dart_interface_code = self._emitters.FileEmitter(dart_interface_file_path)

    template_file = 'interface_%s.darttemplate' % interface_name
    template = self._templates.TryLoad(template_file)
    if not template:
      template = self._templates.Load('interface.darttemplate')

    return DartInterfaceGenerator(
        interface, dart_interface_code,
        template,
        common_prefix, super_interface_name,
        source_filter)

  def ProcessCallback(self, interface, info):
    """Generates a typedef for the callback interface."""
    interface_name = interface.id
    file_path = self._FilePathForDartInterface(interface_name)
    self._ProcessCallback(interface, info, file_path)

  def GenerateLibraries(self, lib_dir):
    pass


  def _FilePathForDartInterface(self, interface_name):
    """Returns the file path of the Dart interface definition."""
    return os.path.join(self._output_dir, 'src', 'interface',
                        '%s.dart' % interface_name)

# ------------------------------------------------------------------------------

class DartInterfaceGenerator(object):
  """Generates Dart Interface definition for one DOM IDL interface."""

  def __init__(self, interface, emitter, template,
               common_prefix, super_interface, source_filter):
    """Generates Dart code for the given interface.

    Args:
      interface -- an IDLInterface instance. It is assumed that all types have
        been converted to Dart types (e.g. int, String), unless they are in the
        same package as the interface.
      common_prefix -- the prefix for the common library, if any.
      super_interface -- the name of the common interface that this interface
        implements, if any.
      source_filter -- if specified, rewrites the names of any superinterfaces
        that are not from these sources to use the common prefix.
    """
    self._interface = interface
    self._emitter = emitter
    self._template = template
    self._common_prefix = common_prefix
    self._super_interface = super_interface
    self._source_filter = source_filter


  def StartInterface(self):
    if self._super_interface:
      typename = self._super_interface
    else:
      typename = self._interface.id


    extends = []
    suppressed_extends = []

    for parent in self._interface.parents:
      # TODO(vsm): Remove source_filter.
      if MatchSourceFilter(self._source_filter, parent):
        # Parent is a DOM type.
        extends.append(DartType(parent.type.id))
      elif '<' in parent.type.id:
        # Parent is a Dart collection type.
        # TODO(vsm): Make this check more robust.
        extends.append(parent.type.id)
      else:
        suppressed_extends.append('%s.%s' %
                                  (self._common_prefix, parent.type.id))

    comment = ' extends'
    extends_str = ''
    if extends:
      extends_str += ' extends ' + ', '.join(extends)
      comment = ','
    if suppressed_extends:
      extends_str += ' /*%s %s */' % (comment, ', '.join(suppressed_extends))

    factory_provider = None
    constructor_info = AnalyzeConstructor(self._interface)
    if constructor_info:
      factory_provider = '_' + typename + 'FactoryProvider';

    if typename in interface_factories:
      factory_provider = interface_factories[typename]

    if factory_provider:
      extends_str += ' default ' + factory_provider

    # TODO(vsm): Add appropriate package / namespace syntax.
    (self._members_emitter,
     self._top_level_emitter) = self._emitter.Emit(
         self._template + '$!TOP_LEVEL',
         ID=typename,
         EXTENDS=extends_str)

    if constructor_info:
      self._members_emitter.Emit(
          '\n'
          '  $CTOR($PARAMS);\n',
          CTOR=typename,
          PARAMS=constructor_info.ParametersInterfaceDeclaration());

    element_type = MaybeTypedArrayElementType(self._interface)
    if element_type:
      self._members_emitter.Emit(
          '\n'
          '  $CTOR(int length);\n'
          '\n'
          '  $CTOR.fromList(List<$TYPE> list);\n'
          '\n'
          '  $CTOR.fromBuffer(ArrayBuffer buffer,'
                            ' [int byteOffset, int length]);\n',
          CTOR=self._interface.id,
          TYPE=DartType(element_type))


  def FinishInterface(self):
    # TODO(vsm): Use typedef if / when that is supported in Dart.
    # Define variant as subtype.
    if (self._super_interface and
        self._interface.id is not self._super_interface):
      consts_emitter = self._top_level_emitter.Emit(
          '\n'
          'interface $NAME extends $BASE {\n'
          '$!CONSTS'
          '}\n',
          NAME=self._interface.id,
          BASE=self._super_interface)
      for const in sorted(self._interface.constants, ConstantOutputOrder):
        self._EmitConstant(consts_emitter, const)

  def AddConstant(self, constant):
    if (not self._super_interface or
        self._interface.id is self._super_interface):
      self._EmitConstant(self._members_emitter, constant)

  def _EmitConstant(self, emitter, constant):
    emitter.Emit('\n  static final $TYPE$NAME = $VALUE;\n',
                 NAME=constant.id,
                 TYPE=TypeOrNothing(DartType(constant.type.id),
                                    constant.type.id),
                 VALUE=constant.value)

  def AddAttribute(self, getter, setter):
    if getter and setter and getter.type.id == setter.type.id:
      self._members_emitter.Emit('\n  $TYPE $NAME;\n',
                                 NAME=DartDomNameOfAttribute(getter),
                                 TYPE=TypeOrVar(DartType(getter.type.id),
                                                getter.type.id))
      return
    if getter and not setter:
      self._members_emitter.Emit('\n  final $TYPE$NAME;\n',
                                 NAME=DartDomNameOfAttribute(getter),
                                 TYPE=TypeOrNothing(DartType(getter.type.id),
                                                    getter.type.id))
      return
    raise Exception('Unexpected getter/setter combination %s %s' %
                    (getter, setter))

  def AddIndexer(self, element_type):
    # Interface inherits all operations from List<element_type>.
    pass

  def AddOperation(self, info):
    """
    Arguments:
      operations - contains the overloads, one or more operations with the same
        name.
    """
    self._members_emitter.Emit('\n'
                               '  $TYPE $NAME($PARAMS);\n',
                               TYPE=info.type_name,
                               NAME=info.name,
                               PARAMS=info.ParametersInterfaceDeclaration())

  def AddStaticOperation(self, info):
    pass

  # Interfaces get secondary members directly via the superinterfaces.
  def AddSecondaryAttribute(self, interface, getter, setter):
    pass

  def AddSecondaryOperation(self, interface, attr):
    pass
