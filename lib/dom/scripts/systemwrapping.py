#!/usr/bin/python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""This module provides shared functionality for the systems to generate
wrapping binding from the IDL database."""

import os
from generator import *
from systembase import *

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
        NAME=DartDomNameOfAttribute(attr),
        TYPE=DartType(attr.type.id),
        METHOD=method_name)

  def _AddSetter(self, attr):
    # FIXME: See comment on getter.
    method_name = self._MethodName('_set_', attr.id)
    self._members_emitter.Emit(
        '\n'
        '  void set $NAME($TYPE value) { $METHOD(this, value); }\n'
        '  static void $METHOD(var _this, $TYPE value) native;\n',
        NAME=DartDomNameOfAttribute(attr),
        TYPE=DartType(attr.type.id),
        METHOD=method_name)

  def AddSecondaryAttribute(self, interface, getter, setter):
    self._SecondaryContext(interface)
    self.AddAttribute(getter, setter)

  def AddSecondaryOperation(self, interface, info):
    self._SecondaryContext(interface)
    self.AddOperation(info)

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
    dart_element_type = DartType(element_type)
    if self._HasNativeIndexGetter(self._interface):
      self._EmitNativeIndexGetter(self._interface, dart_element_type)
    else:
      self._members_emitter.Emit(
          '\n'
          '  $TYPE operator[](int index) {\n'
          '    return item(index);\n'
          '  }\n',
          TYPE=dart_element_type)

    if self._HasNativeIndexSetter(self._interface):
      self._EmitNativeIndexSetter(self._interface, dart_element_type)
    else:
      self._members_emitter.Emit(
          '\n'
          '  void operator[]=(int index, $TYPE value) {\n'
          '    throw new UnsupportedOperationException("Cannot assign element of immutable List.");\n'
          '  }\n',
          TYPE=dart_element_type)

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
        TYPE=dart_element_type)

  def _HasNativeIndexGetter(self, interface):
    return ('IndexedGetter' in interface.ext_attrs or
            'NumericIndexedGetter' in interface.ext_attrs)

  def _EmitNativeIndexGetter(self, interface, dart_element_type):
    method_name = '_index'
    self._members_emitter.Emit(
        '\n'
        '  $TYPE operator[](int index) { return $METHOD(this, index); }\n'
        '  static $TYPE $METHOD(var _this, int index) native;\n',
        TYPE=dart_element_type, METHOD=method_name)

  def _HasNativeIndexSetter(self, interface):
    return 'CustomIndexedSetter' in interface.ext_attrs

  def _EmitNativeIndexSetter(self, interface, dart_element_type):
    method_name = '_set_index'
    self._members_emitter.Emit(
        '\n'
        '  void operator[]=(int index, $TYPE value) {\n'
        '    return $METHOD(this, index, value);\n'
        '  }\n'
        '  static $METHOD(_this, index, value) native;\n',
        TYPE=dart_element_type, METHOD=method_name)

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

    def ArgNameAndUnwrapper(param_info, overload_arg):
      return (param_info.name,
              UnwrapArgExpression(param_info.name, param_info.dart_type))

    names_and_unwrappers = [ArgNameAndUnwrapper(info.param_infos[i], arg)
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

    def ShouldGenerateSingleOperation():
      if position == len(info.param_infos):
        if len(overloads) > 1:
          raise Exception('Duplicate operations ' + str(overloads))
        return True

      # Check if we dispatch on RequiredCppParameter arguments.  In this
      # case all trailing arguments must be RequiredCppParameter and there
      # is no need in dispatch.
      # TODO(antonm): better diagnositics.
      if position >= len(overloads[0].arguments):
        def IsRequiredCppParameter(arg):
          return 'RequiredCppParameter' in arg.ext_attrs
        last_overload = overloads[-1]
        if (len(last_overload.arguments) > position and
            IsRequiredCppParameter(last_overload.arguments[position])):
          for overload in overloads:
            args = overload.arguments[position:]
            if not all([IsRequiredCppParameter(arg) for arg in args]):
              raise Exception('Invalid overload for RequiredCppParameter')
          return True

      return False

    if ShouldGenerateSingleOperation():
      self.GenerateSingleOperation(emitter, info, indent, overloads[-1])
      return False

    # FIXME: Consider a simpler dispatch that iterates over the
    # overloads and generates an overload specific check.  Revisit
    # when we move to named optional arguments.

    # Partition the overloads to divide and conquer on the dispatch.
    positive = []
    negative = []
    first_overload = overloads[0]
    param = info.param_infos[position]

    if position < len(first_overload.arguments):
      # FIXME: This will not work if the second overload has a more
      # precise type than the first.  E.g.,
      # void foo(Node x);
      # void foo(Element x);
      type = DartType(first_overload.arguments[position].type.id)
      test = TypeCheck(param.name, type)
      pred = lambda op: len(op.arguments) > position and DartType(op.arguments[position].type.id) == type
    else:
      type = None
      test = NullCheck(param.name)
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
    if type == param.dart_type:
      return self.GenerateDispatch(
          emitter, info, indent, position + 1, positive)

    # Otherwise the overloads have the same type but the type is a subtype of
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
