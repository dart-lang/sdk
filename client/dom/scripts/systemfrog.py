#!/usr/bin/python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""This module provides shared functionality for the systems to generate
frog binding from the IDL database."""

import os
from generator import *
from systembase import *

class FrogSystem(System):

  def __init__(self, templates, database, emitters, output_dir):
    super(FrogSystem, self).__init__(
        templates, database, emitters, output_dir)
    self._dart_frog_file_paths = []

  def InterfaceGenerator(self,
                         interface,
                         common_prefix,
                         super_interface_name,
                         source_filter):
    """."""
    dart_frog_file_path = self._FilePathForFrogImpl(interface.id)
    self._dart_frog_file_paths.append(dart_frog_file_path)

    template_file = 'impl_%s.darttemplate' % interface.id
    template = self._templates.TryLoad(template_file)
    if not template:
      template = self._templates.Load('frog_impl.darttemplate')

    dart_code = self._emitters.FileEmitter(dart_frog_file_path)
    return FrogInterfaceGenerator(self, interface, template,
                                  super_interface_name, dart_code)

  def GenerateLibraries(self, lib_dir):
    self._GenerateLibFile(
        'frog_dom.darttemplate',
        os.path.join(lib_dir, 'dom_frog.dart'),
        (self._interface_system._dart_interface_file_paths +
         self._interface_system._dart_callback_file_paths +
         self._dart_frog_file_paths))

  def Finish(self):
    pass

  def _FilePathForFrogImpl(self, interface_name):
    """Returns the file path of the Frog implementation."""
    return os.path.join(self._output_dir, 'src', 'frog',
                        '%s.dart' % interface_name)

# ------------------------------------------------------------------------------

class FrogInterfaceGenerator(object):
  """Generates a Frog class for a DOM IDL interface."""

  def __init__(self, system, interface, template, super_interface, dart_code):
    """Generates Dart code for the given interface.

    Args:

      interface: an IDLInterface instance. It is assumed that all types have
          been converted to Dart types (e.g. int, String), unless they are in
          the same package as the interface.
      template: A string template.
      super_interface: A string or None, the name of the common interface that
          this interface implements, if any.
      dart_code: an Emitter for the file containing the Dart implementation
          class.
    """
    self._system = system
    self._interface = interface
    self._template = template
    self._super_interface = super_interface
    self._dart_code = dart_code
    self._current_secondary_parent = None


  def StartInterface(self):
    interface = self._interface
    interface_name = interface.id
    self._class_name = self._ImplClassName(interface_name)

    base = None
    if interface.parents:
      supertype = interface.parents[0].type.id
      if IsDartCollectionType(supertype):
        # List methods are injected in AddIndexer.
        pass
      else:
        base = self._ImplClassName(supertype)

    native_spec = MakeNativeSpec(interface.javascript_binding_name)

    if base:
      extends = ' extends ' + base
    elif native_spec[0] == '=':
      # The implementation is a singleton with no prototype.
      extends = ''
    else:
      extends = ' extends _DOMTypeJs'

    # TODO: Include all implemented interfaces, including other Lists.
    implements = [interface_name]
    element_type = MaybeTypedArrayElementType(self._interface)
    if element_type:
      implements.append('List<' + element_type + '>')

    self._members_emitter = self._dart_code.Emit(
        self._template,
        #class $CLASSNAME$EXTENDS$IMPLEMENTS$NATIVESPEC {
        #$!MEMBERS
        #}
        CLASSNAME=self._class_name,
        EXTENDS=extends,
        IMPLEMENTS=' implements ' + ', '.join(implements),
        NATIVESPEC=' native "' + native_spec + '"')

    element_type = MaybeTypedArrayElementType(interface)
    if element_type:
      self.AddTypedArrayConstructors(element_type)


  def FinishInterface(self):
    """."""
    pass

  def _ImplClassName(self, type_name):
    return '_' + type_name + 'Js'

  def _NarrowToImplementationType(self, type_name):
    # TODO(sra): Move into the 'system' and cache the result.
    if type_name == 'EventListener':
      # Callbacks are typedef functions so don't have a class.
      return type_name
    if self._system._database.HasInterface(type_name):
      interface = self._system._database.GetInterface(type_name)
      if RecognizeCallback(interface):
        # Callbacks are typedef functions so don't have a class.
        return type_name
      else:
        return self._ImplClassName(type_name)
    return type_name

  def _NarrowInputType(self, type_name):
    return self._NarrowToImplementationType(type_name)

  def _NarrowOutputType(self, type_name):
    return self._NarrowToImplementationType(type_name)

  def AddConstant(self, constant):
    # Since we are currently generating native classes without interfaces,
    # generate the constants as part of the class.  This will need to go away
    # if we revert back to generating interfaces.
    self._members_emitter.Emit('\n  static final $TYPE $NAME = $VALUE;\n',
                               NAME=constant.id,
                               TYPE=constant.type.id,
                               VALUE=constant.value)

    pass

  def AddAttribute(self, getter, setter):
    output_type = getter and self._NarrowOutputType(getter.type.id)
    input_type = setter and self._NarrowInputType(setter.type.id)

    # If the (getter, setter) pair is shadowing, we can't generate a shadowing
    # field (Issue 1633).
    (super_getter, super_getter_interface) = self._FindShadowedAttribute(getter)
    (super_setter, super_setter_interface) = self._FindShadowedAttribute(setter)
    if super_getter or super_setter:
      if getter and not setter and super_getter and not super_setter:
        if getter.type.id == super_getter.type.id:
          # Compatible getter, use the superclass property.  This works because
          # JavaScript will do its own dynamic dispatch.
          self._members_emitter.Emit(
              '\n'
              '  // Use implementation from $SUPER.\n'
              '  // final $TYPE $NAME;\n',
              SUPER=super_getter_interface.id,
              NAME=getter.id, TYPE=output_type)
          return

      self._members_emitter.Emit('\n  // Shadowing definition.')
      self._AddAttributeUsingProperties(getter, setter)
      return

    if getter and setter and input_type == output_type:
      self._members_emitter.Emit(
          '\n  $TYPE $NAME;\n',
          NAME=getter.id, TYPE=output_type)
      return
    if getter and not setter:
      self._members_emitter.Emit(
          '\n  final $TYPE $NAME;\n',
          NAME=getter.id, TYPE=output_type)
      return
    self._AddAttributeUsingProperties(getter, setter)

  def _AddAttributeUsingProperties(self, getter, setter):
    if getter:
      self._AddGetter(getter)
    if setter:
      self._AddSetter(setter)

  def _AddGetter(self, attr):
    # TODO(sra): Remove native body when Issue 829 fixed.
    self._members_emitter.Emit(
        '\n  $TYPE get $NAME() native "return this.$NAME;";\n',
        NAME=attr.id, TYPE=self._NarrowOutputType(attr.type.id))

  def _AddSetter(self, attr):
    # TODO(sra): Remove native body when Issue 829 fixed.
    self._members_emitter.Emit(
        '  void set $NAME($TYPE value) native "this.$NAME = value;";\n',
        NAME=attr.id, TYPE=self._NarrowInputType(attr.type.id))

  def _FindShadowedAttribute(self, attr):
    """Returns (attribute, superinterface) or (None, None)."""
    def FindInParent(interface):
      """Returns matching attribute in parent, or None."""
      if interface.parents:
        parent = interface.parents[0]
        if IsDartCollectionType(parent.type.id):
          return (None, None)
        if self._system._database.HasInterface(parent.type.id):
          parent_interface = self._system._database.GetInterface(parent.type.id)
          attr2 = FindMatchingAttribute(parent_interface, attr)
          if attr2:
            return (attr2, parent_interface)
          return FindInParent(parent_interface)
      return (None, None)

    return FindInParent(self._interface) if attr else (None, None)


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
    self._members_emitter.Emit(
        '\n'
        '  $TYPE operator[](int index) native "return this[index];";\n',
        TYPE=self._NarrowOutputType(element_type))

    if 'CustomIndexedSetter' in self._interface.ext_attrs:
      self._members_emitter.Emit(
          '\n'
          '  void operator[]=(int index, $TYPE value) native "this[index] = value";\n',
          TYPE=self._NarrowInputType(element_type))
    else:
      self._members_emitter.Emit(
          '\n'
          '  void operator[]=(int index, $TYPE value) {\n'
          '    throw new UnsupportedOperationException("Cannot assign element of immutable List.");\n'
          '  }\n',
          TYPE=self._NarrowInputType(element_type))

    # TODO(sra): Use separate mixins for mutable implementations of List<T>.
    # TODO(sra): Use separate mixins for typed array implementations of List<T>.
    template_file = 'immutable_list_mixin.darttemplate'
    template = self._system._templates.Load(template_file)
    self._members_emitter.Emit(template, E=element_type)


  def AddTypedArrayConstructors(self, element_type):
    self._members_emitter.Emit(
        '\n'
        '  factory $CTOR(int length) =>  _construct_$CTOR(length);\n'
        '\n'
        '  factory $CTOR.fromList(List<$TYPE> list) => _construct_$CTOR(list);\n'
        '\n'
        '  factory $CTOR.fromBuffer(ArrayBuffer buffer) => _construct_$CTOR(buffer);\n'
        '\n'
        '  static _construct_$CTOR(arg) native \'return new $CTOR(arg);\';\n',
        CTOR=self._interface.id,
        TYPE=element_type)


  def AddOperation(self, info):
    """
    Arguments:
      info: An OperationInfo object.
    """
    # TODO(vsm): Handle overloads.
    self._members_emitter.Emit(
        '\n'
        '  $TYPE $NAME($PARAMS) native;\n',
        TYPE=self._NarrowOutputType(info.type_name),
        NAME=info.name,
        PARAMS=info.ParametersImplementationDeclaration(
            lambda type_name: self._NarrowInputType(type_name)))
