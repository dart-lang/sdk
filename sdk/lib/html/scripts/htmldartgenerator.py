#!/usr/bin/python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""This module provides shared functionality for the system to generate
dart:html APIs from the IDL database."""

from generator import DartDomNameOfAttribute

class HtmlDartGenerator(object):
  def __init__(self, interface, options):
    self._interface = interface

  def EmitAttributeDocumentation(self, attribute):
    dom_name = DartDomNameOfAttribute(attribute)
    self._members_emitter.Emit('\n  /** @domName $DOMINTERFACE.$DOMNAME */',
        DOMINTERFACE=attribute.doc_js_interface_name,
        DOMNAME=dom_name)

  def EmitOperationDocumentation(self, operation):
    self._members_emitter.Emit('\n  /** @domName $DOMINTERFACE.$DOMNAME */',
        DOMINTERFACE=operation.overloads[0].doc_js_interface_name,
        DOMNAME=operation.name)

  def AdditionalImplementedInterfaces(self):
    # TODO: Include all implemented interfaces, including other Lists.
    implements = []
    if self._interface_type_info.is_typed_array():
      element_type = self._interface_type_info.list_item_type()
      implements.append('List<%s>' % self._DartType(element_type))
    if self._interface_type_info.list_item_type():
      item_type_info = self._type_registry.TypeInfo(
          self._interface_type_info.list_item_type())
      implements.append('List<%s>' % item_type_info.dart_type())
    return implements

  def AddConstructors(self, constructors, factory_provider, class_name,
      base_class):
    for constructor_info in constructors:
      self._AddConstructor(constructor_info, factory_provider)

    typed_array_type = None
    for interface in self._database.Hierarchy(self._interface):
      type_info = self._type_registry.TypeInfo(interface.id)
      if type_info.is_typed_array():
        typed_array_type = type_info.list_item_type()
        break
    if typed_array_type:
      self._members_emitter.Emit(
          '\n'
          '  factory $CTOR(int length) =>\n'
          '    $FACTORY.create$(CTOR)(length);\n'
          '\n'
          '  factory $CTOR.fromList(List<$TYPE> list) =>\n'
          '    $FACTORY.create$(CTOR)_fromList(list);\n'
          '\n'
          '  factory $CTOR.fromBuffer(ArrayBuffer buffer, [int byteOffset, int length]) => \n'
          '    $FACTORY.create$(CTOR)_fromBuffer(buffer, byteOffset, length);\n',
        CTOR=self._interface.id,
        TYPE=self._DartType(typed_array_type),
        FACTORY=factory_provider)

  def _AddConstructor(self, constructor_info, factory_provider):
      constructor_info.GenerateFactoryInvocation(
          self._DartType, self._members_emitter, factory_provider)

  def DeclareAttribute(self, attribute, type_name, html_name, read_only):
    # Declares an attribute but does not include the code to invoke it.
    self.EmitAttributeDocumentation(attribute)
    if read_only:
      template = '\n  $TYPE get $NAME;\n'
    else:
      template = '\n  $TYPE $NAME;\n'

    self._members_emitter.Emit(template,
        NAME=html_name,
        TYPE=type_name)

  def DeclareOperation(self, operation, type_name, html_name):
    # Declares an operation but does not include the code to invoke it.
    self.EmitOperationDocumentation(operation)
    self._members_emitter.Emit(
             '\n'
             '  $TYPE $NAME($PARAMS);\n',
             TYPE=type_name,
             NAME=html_name,
             PARAMS=operation.ParametersDeclaration(self._DartType))
