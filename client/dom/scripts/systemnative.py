#!/usr/bin/python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""This module provides shared functionality for the systems to generate
native binding from the IDL database."""

import emitter
import os
import systemwrapping
from generator import *
from systembase import *

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

    if IsPureInterface(interface_name):
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


class NativeImplementationGenerator(systemwrapping.WrappingInterfaceGenerator):
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
    if not self._IsConstructable():
      return

    # TODO(antonm): currently we don't have information about number of arguments expected by
    # the constructor, so name only dispatch.
    self._cpp_resolver_emitter.Emit(
        '    if (name == "$(INTERFACE_NAME)_constructor_Callback")\n'
        '        return Dart$(INTERFACE_NAME)Internal::constructorCallback;\n',
        INTERFACE_NAME=self._interface.id)


    constructor_info = AnalyzeConstructor(self._interface)
    if constructor_info is None:
      # We have a custom implementation for it.
      self._cpp_declarations_emitter.Emit(
          '\n'
          'void constructorCallback(Dart_NativeArguments);\n')
      return

    raises_dom_exceptions = 'ConstructorRaisesException' in self._interface.ext_attrs
    raises_dart_exceptions = raises_dom_exceptions or len(constructor_info.idl_args) > 0
    type_info = GetIDLTypeInfo(self._interface)
    arguments = []
    parameter_definitions_emitter = emitter.Emitter()
    if 'CallWith' in self._interface.ext_attrs:
      call_with = self._interface.ext_attrs['CallWith']
      if call_with == 'ScriptExecutionContext':
        raises_dart_exceptions = True
        parameter_definitions_emitter.Emit(
            '        ScriptExecutionContext* context = DartUtilities::scriptExecutionContext();\n'
            '        if (!context) {\n'
            '            exception = Dart_NewString("Failed to create an object");\n'
            '            goto fail;\n'
            '        }\n')
        arguments.append('context')
      else:
        raise Exception('Unsupported CallWith=%s attribute' % call_with)

    # Process constructor arguments.
    for (i, arg) in enumerate(constructor_info.idl_args):
      self._GenerateParameterAdapter(parameter_definitions_emitter, arg, i - 1)
      arguments.append(arg.id)

    self._GenerateNativeCallback(
        callback_name='constructorCallback',
        idl_node=self._interface,
        parameter_definitions=parameter_definitions_emitter.Fragments(),
        needs_receiver=False, function_name='%s::create' % type_info.native_type(),
        arguments=arguments,
        idl_return_type=self._interface,
        raises_dart_exceptions=raises_dart_exceptions,
        raises_dom_exceptions=raises_dom_exceptions)


  def _ImplClassName(self, interface_name):
    return interface_name + 'Implementation'

  def _IsConstructable(self):
    # FIXME: support ConstructorTemplate.
    # FIXME: support NamedConstructor.
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
    flags = ''
    if idl_argument.ext_attrs.get('Optionial') == 'DefaultIsNullString':
      flags = ', DartUtilities::ConvertNullToEmptyString'
    emitter.Emit(
        '\n'
        '        const $ADAPTER_TYPE $NAME(Dart_GetNativeArgument(args, $INDEX)$FLAGS);\n'
        '        if (!$NAME.conversionSuccessful()) {\n'
        '            exception = $NAME.exception();\n'
        '            goto fail;\n'
        '        }\n',
        ADAPTER_TYPE=adapter_type,
        NAME=idl_argument.id,
        INDEX=index + 1,
        FLAGS=flags)

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
