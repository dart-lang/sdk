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

  def __init__(self, options):
    super(InterfacesSystem, self).__init__(options)
    self._dart_interface_file_paths = []


  def ProcessInterface(self, interface):
    """."""
    interface_name = interface.id
    dart_interface_file_path = self._FilePathForDartInterface(interface_name)

    self._dart_interface_file_paths.append(dart_interface_file_path)

    dart_interface_code = self._emitters.FileEmitter(dart_interface_file_path)

    template_file = 'interface_%s.darttemplate' % interface_name
    template = self._templates.TryLoad(template_file)
    if not template:
      template = self._templates.Load('interface.darttemplate')

    DartInterfaceGenerator(
        self, interface, dart_interface_code, template).Generate()

  def ProcessCallback(self, interface, info):
    """Generates a typedef for the callback interface."""
    interface_name = interface.id
    file_path = self._FilePathForDartInterface(interface_name)
    self._ProcessCallback(interface, info, file_path)

  def GenerateLibraries(self):
    pass


  def _FilePathForDartInterface(self, interface_name):
    """Returns the file path of the Dart interface definition."""
    return os.path.join(self._output_dir, 'src', 'interface',
                        '%s.dart' % interface_name)

# ------------------------------------------------------------------------------

class DartInterfaceGenerator(systembase.BaseGenerator):
  """Generates Dart Interface definition for one DOM IDL interface."""

  def __init__(self, system, interface, emitter, template):
    """Generates Dart code for the given interface.

    Args:
      interface -- an IDLInterface instance. It is assumed that all types have
        been converted to Dart types (e.g. int, String), unless they are in the
        same package as the interface.
      super_interface -- the name of the common interface that this interface
        implements, if any.
    """
    super(DartInterfaceGenerator, self).__init__(system._database, interface)
    self._system = system
    self._emitter = emitter
    self._template = template
    self._super_interface = interface.ext_attrs.get(
        'synthesizedSuperInterfaceName', None)

  def StartInterface(self):
    if self._super_interface:
      typename = self._super_interface
    else:
      typename = self._interface.id


    extends = []
    suppressed_extends = []

    for parent in self._interface.parents:
      # TODO(vsm): Remove source_filter.
      if MatchSourceFilter(parent):
        # Parent is a DOM type.
        extends.append(self._DartType(parent.type.id))
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
      factory_provider = '_' + typename + 'FactoryProvider'

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
          PARAMS=constructor_info.ParametersInterfaceDeclaration(self._DartType))

    element_type = MaybeTypedArrayElementTypeInHierarchy(
        self._interface, self._system._database)
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
          TYPE=self._DartType(element_type))


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
    emitter.Emit('\n  static const $TYPE$NAME = $VALUE;\n',
                 NAME=constant.id,
                 TYPE=TypeOrNothing(self._DartType(constant.type.id),
                                    constant.type.id),
                 VALUE=constant.value)

  def AddAttribute(self, attribute):
    getter = attribute
    setter = attribute if not systembase.IsReadOnly(attribute) else None
    if getter and setter and getter.type.id == setter.type.id:
      self._members_emitter.Emit('\n  $TYPE $NAME;\n',
                                 NAME=DartDomNameOfAttribute(getter),
                                 TYPE=TypeOrVar(self._DartType(getter.type.id),
                                                getter.type.id))
      return
    if getter and not setter:
      self._members_emitter.Emit('\n  final $TYPE$NAME;\n',
                                 NAME=DartDomNameOfAttribute(getter),
                                 TYPE=TypeOrNothing(self._DartType(getter.type.id),
                                                    getter.type.id))
      return
    raise Exception('Unexpected getter/setter combination %s %s' %
                    (getter, setter))

  def AddOperation(self, info):
    """
    Arguments:
      operations - contains the overloads, one or more operations with the same
        name.
    """
    self._members_emitter.Emit('\n'
                               '  $TYPE $NAME($PARAMS);\n',
                               TYPE=self._DartType(info.type_name),
                               NAME=info.name,
                               PARAMS=info.ParametersInterfaceDeclaration(self._DartType))
