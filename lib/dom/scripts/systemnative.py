#!/usr/bin/python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""This module provides shared functionality for the systems to generate
native binding from the IDL database."""

import emitter
import os
from generator import *
from systembase import *
from systemhtml import DomToHtmlEvent, DomToHtmlEvents

class NativeImplementationSystem(System):

  def __init__(self, templates, database, html_renames, emitters, auxiliary_dir,
               output_dir):
    super(NativeImplementationSystem, self).__init__(
        templates, database, emitters, output_dir)

    self._html_renames = html_renames
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

    return NativeImplementationGenerator(self, interface,
        self._emitters.FileEmitter(dart_impl_path),
        self._emitters.FileEmitter(cpp_header_path),
        self._emitters.FileEmitter(cpp_impl_path),
        self._BaseDefines(interface),
        self._templates)

  def ProcessCallback(self, interface, info):
    self._interface = interface

    dart_interface_path = self._FilePathForDartInterface(self._interface.id)
    self._dom_public_files.append(dart_interface_path)

    if IsPureInterface(self._interface.id):
      return None

    cpp_impl_includes = set()
    cpp_header_handlers_emitter = emitter.Emitter()
    cpp_impl_handlers_emitter = emitter.Emitter()
    class_name = 'Dart%s' % self._interface.id
    for operation in interface.operations:
      if operation.type.id == 'void':
        return_prefix = ''
        error_return = ''
      else:
        return_prefix = 'return '
        error_return = ' false'

      parameters = []
      arguments = []
      for argument in operation.arguments:
        argument_type_info = GetIDLTypeInfo(argument.type.id)
        parameters.append('%s %s' % (argument_type_info.parameter_type(),
                                     argument.id))
        arguments.append(argument_type_info.to_dart_conversion(argument.id))
        cpp_impl_includes |= set(argument_type_info.conversion_includes())

      native_return_type = GetIDLTypeInfo(operation.type.id).native_type()
      cpp_header_handlers_emitter.Emit(
          '\n'
          '    virtual $TYPE handleEvent($PARAMETERS);\n',
          TYPE=native_return_type, PARAMETERS=', '.join(parameters))

      arguments_declaration = 'Dart_Handle arguments[] = { %s }' % ', '.join(arguments)
      if not len(arguments):
        arguments_declaration = 'Dart_Handle* arguments = 0'
      cpp_impl_handlers_emitter.Emit(
          '\n'
          '$TYPE $CLASS_NAME::handleEvent($PARAMETERS)\n'
          '{\n'
          '    if (!m_callback.isolate()->isAlive())\n'
          '        return$ERROR_RETURN;\n'
          '    DartIsolate::Scope scope(m_callback.isolate());\n'
          '    DartApiScope apiScope;\n'
          '    $ARGUMENTS_DECLARATION;\n'
          '    $(RETURN_PREFIX)m_callback.handleEvent($ARGUMENT_COUNT, arguments);\n'
          '}\n',
          TYPE=native_return_type,
          CLASS_NAME=class_name,
          PARAMETERS=', '.join(parameters),
          ERROR_RETURN=error_return,
          RETURN_PREFIX=return_prefix,
          ARGUMENTS_DECLARATION=arguments_declaration,
          ARGUMENT_COUNT=len(arguments))

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
        INCLUDES=_GenerateCPPIncludes(cpp_impl_includes),
        INTERFACE=self._interface.id,
        HANDLERS=cpp_impl_handlers_emitter.Fragments())

  def GenerateLibraries(self):
    auxiliary_dir = os.path.relpath(self._auxiliary_dir, self._output_dir)

    # Generate dom_public.dart.
    self._GenerateLibFile(
        'dom_public.darttemplate',
        os.path.join(self._output_dir, 'dom_public.dart'),
        self._dom_public_files,
        AUXILIARY_DIR=MassagePath(auxiliary_dir));

    # Generate dom_impl.dart.
    self._GenerateLibFile(
        'dom_impl.darttemplate',
        os.path.join(self._output_dir, 'dom_impl.dart'),
        self._dom_impl_files,
        AUXILIARY_DIR=MassagePath(auxiliary_dir));

    # Generate DartDerivedSourcesXX.cpp.
    partitions = 20 # FIXME: this should be configurable.
    sources_count = len(self._cpp_impl_files)
    for i in range(0, partitions):
      derived_sources_path = os.path.join(self._output_dir,
          'DartDerivedSources%02i.cpp' % (i + 1))

      includes_emitter = emitter.Emitter()
      for impl_file in self._cpp_impl_files[i::partitions]:
          path = os.path.relpath(impl_file, os.path.dirname(derived_sources_path))
          includes_emitter.Emit('#include "$PATH"\n', PATH=path)

      derived_sources_emitter = self._emitters.FileEmitter(derived_sources_path)
      derived_sources_emitter.Emit(
          self._templates.Load('cpp_derived_sources.template'),
          INCLUDES=includes_emitter.Fragments())

    # Generate DartResolver.cpp.
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

  def _FilePathForDartFactoryProvider(self, interface_name):
    return os.path.join(self._output_dir, 'dart',
                        '_%sFactoryProvider.dart' % interface_name)

  def _FilePathForDartFactoryProviderImplementation(self, interface_name):
    return os.path.join(self._output_dir, 'dart',
                        '%sFactoryProviderImplementation.dart' % interface_name)

  def _FilePathForCppHeader(self, interface_name):
    return os.path.join(self._output_dir, 'cpp', 'Dart%s.h' % interface_name)

  def _FilePathForCppImplementation(self, interface_name):
    return os.path.join(self._output_dir, 'cpp', 'Dart%s.cpp' % interface_name)


class NativeImplementationGenerator(object):
  """Generates Dart implementation for one DOM IDL interface."""

  def __init__(self, system, interface,
               dart_impl_emitter, cpp_header_emitter, cpp_impl_emitter,
               base_members, templates):
    """Generates Dart and C++ code for the given interface.

    Args:
      system: The NativeImplementationSystem.
      interface: an IDLInterface instance. It is assumed that all types have
          been converted to Dart types (e.g. int, String), unless they are in
          the same package as the interface.
      dart_impl_emitter: an Emitter for the file containing the Dart
         implementation class.
      cpp_header_emitter: an Emitter for the file containing the C++ header.
      cpp_impl_emitter: an Emitter for the file containing the C++
         implementation.
      base_members: a set of names of members defined in a base class.  This is
          used to avoid static member 'overriding' in the generated Dart code.
    """
    self._system = system
    self._interface = interface
    self._dart_impl_emitter = dart_impl_emitter
    self._cpp_header_emitter = cpp_header_emitter
    self._cpp_impl_emitter = cpp_impl_emitter
    self._base_members = base_members
    self._templates = templates
    self._current_secondary_parent = None

  def StartInterface(self):
    self._class_name = self._ImplClassName(self._interface.id)
    self._interface_type_info = GetIDLTypeInfo(self._interface.id)
    self._members_emitter = emitter.Emitter()
    self._cpp_declarations_emitter = emitter.Emitter()
    self._cpp_impl_includes = set()
    self._cpp_definitions_emitter = emitter.Emitter()
    self._cpp_resolver_emitter = emitter.Emitter()

    self._GenerateConstructors()
    self._GenerateEvents()

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
    if constructor_info:
      self._EmitFactoryProvider(self._interface.id, constructor_info)

    if constructor_info is None:
      # We have a custom implementation for it.
      self._cpp_declarations_emitter.Emit(
          '\n'
          'void constructorCallback(Dart_NativeArguments);\n')
      return

    raises_dom_exceptions = 'ConstructorRaisesException' in self._interface.ext_attrs
    raises_exceptions = raises_dom_exceptions or len(constructor_info.idl_args) > 0
    arguments = []
    parameter_definitions_emitter = emitter.Emitter()
    create_function = 'create'
    if 'NamedConstructor' in self._interface.ext_attrs:
      raises_exceptions = True
      parameter_definitions_emitter.Emit(
            '        DOMWindow* domWindow = DartUtilities::domWindowForCurrentIsolate();\n'
            '        if (!domWindow) {\n'
            '            exception = Dart_NewString("Failed to fetch domWindow");\n'
            '            goto fail;\n'
            '        }\n'
            '        Document* document = domWindow->document();\n')
      self._cpp_impl_includes.add('"DOMWindow.h"')
      arguments.append('document')
      create_function = 'createForJSConstructor'
    if 'CallWith' in self._interface.ext_attrs:
      call_with = self._interface.ext_attrs['CallWith']
      if call_with == 'ScriptExecutionContext':
        raises_exceptions = True
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
    for (i, argument) in enumerate(constructor_info.idl_args):
      argument_expression = self._GenerateToNative(
          parameter_definitions_emitter, argument, i)
      arguments.append(argument_expression)

    function_expression = '%s::%s' % (self._interface_type_info.native_type(), create_function)
    invocation = self._GenerateWebCoreInvocation(function_expression, arguments,
        self._interface.id, self._interface.ext_attrs, raises_dom_exceptions)
    self._GenerateNativeCallback(callback_name='constructorCallback',
        parameter_definitions=parameter_definitions_emitter.Fragments(),
        needs_receiver=False, invocation=invocation,
        raises_exceptions=raises_exceptions)

  def _GenerateEvents(self):
    if self._interface.id == 'DocumentFragment':
      # Interface DocumentFragment extends Element in dart:html but this fact
      # is not reflected in idls.
      self._EmitEventGetter('ElementEventsImplementation')
      return

    events_attributes = [attr for attr in self._interface.attributes
                         if attr.type.id == 'EventListener']
    if not 'EventTarget' in self._interface.ext_attrs and not events_attributes:
      return

    def IsEventTarget(interface):
      return ('EventTarget' in interface.ext_attrs and
              interface.id != 'EventTarget')
    is_root = not _FindParent(self._interface, self._system._database, IsEventTarget)
    if is_root:
      self._members_emitter.Emit('  EventsImplementation _on;\n')

    if not events_attributes:
      if is_root:
        self._EmitEventGetter('EventsImplementation')
      return

    events_class = '%sEventsImplementation' % self._interface.id
    self._EmitEventGetter(events_class)

    def HasEventAttributes(interface):
      return any([a.type.id == 'EventListener' for a in interface.attributes])
    parent = _FindParent(self._interface, self._system._database, HasEventAttributes)
    if parent:
      parent_events_class = '%sEventsImplementation' % parent.id
    else:
      parent_events_class = 'EventsImplementation'
    html_inteface = self._system._html_renames.get(self._interface.id, self._interface.id)
    events_members = self._dart_impl_emitter.Emit(
        '\n'
        'class $EVENTS_CLASS extends $PARENT_EVENTS_CLASS implements $EVENTS_INTERFACE {\n'
        '  $EVENTS_CLASS(_ptr) : super(_ptr);\n'
        '$!MEMBERS\n'
        '}\n',
        EVENTS_CLASS=events_class,
        PARENT_EVENTS_CLASS=parent_events_class,
        EVENTS_INTERFACE='html.%sEvents' % html_inteface)

    events_attributes = DomToHtmlEvents(self._interface.id, events_attributes)
    for event_name in events_attributes:
      events_members.Emit(
          '  EventListenerList get $HTML_NAME() => this[\'$DOM_NAME\'];\n',
          HTML_NAME=DomToHtmlEvent(event_name),
          DOM_NAME=event_name)

  def _EmitEventGetter(self, events_class):
    self._members_emitter.Emit(
        '\n'
        '  $EVENTS_CLASS get on() {\n'
        '    if (_on === null) _on = new $EVENTS_CLASS(this);\n'
        '    return _on;\n'
        '  }\n',
        EVENTS_CLASS=events_class)

  def _ImplClassName(self, interface_name):
    return interface_name + 'Implementation'

  def _BaseClassName(self):
    if not self._interface.parents:
      return 'DOMWrapperBase'

    supertype = self._interface.parents[0].type.id

    # FIXME: We're currently injecting List<..> and EventTarget as
    # supertypes in dart.idl. We should annotate/preserve as
    # attributes instead.  For now, this hack lets the self._interfaces
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
      if not [op for op in self._interface.operations if op.id == 'addEventListener']:
        return self._ImplClassName(supertype)
      return 'DOMWrapperBase'

    return self._ImplClassName(supertype)

  def _IsConstructable(self):
    # FIXME: support ConstructorTemplate.
    return set(['CustomConstructor', 'V8CustomConstructor', 'Constructor', 'NamedConstructor']) & set(self._interface.ext_attrs)

  def _EmitFactoryProvider(self, interface_name, constructor_info):
    factory_provider = '_' + interface_name + 'FactoryProvider'
    implementation_class = interface_name + 'FactoryProviderImplementation'
    implementation_function = 'create' + interface_name
    native_implementation_function = '%s_constructor_Callback' % interface_name

    # Emit private factory provider in public library.
    template_file = 'factoryprovider_%s.darttemplate' % interface_name
    template = self._system._templates.TryLoad(template_file)
    if not template:
      template = self._system._templates.Load('factoryprovider.darttemplate')

    dart_impl_path = self._system._FilePathForDartFactoryProvider(
        interface_name)
    self._system._dom_public_files.append(dart_impl_path)

    emitter = self._system._emitters.FileEmitter(dart_impl_path)
    emitter.Emit(
        template,
        FACTORY_PROVIDER=factory_provider,
        CONSTRUCTOR=interface_name,
        PARAMETERS=constructor_info.ParametersImplementationDeclaration(),
        IMPL_CLASS=implementation_class,
        IMPL_FUNCTION=implementation_function,
        ARGUMENTS=constructor_info.ParametersAsArgumentList())

    # Emit public implementation in implementation libary.
    dart_impl_path = self._system._FilePathForDartFactoryProviderImplementation(
        interface_name)
    self._system._dom_impl_files.append(dart_impl_path)
    emitter = self._system._emitters.FileEmitter(dart_impl_path)
    emitter.Emit(
        'class $IMPL_CLASS {\n'
        '  static $INTERFACE_NAME $IMPL_FUNCTION($PARAMETERS)\n'
        '      native "$NATIVE_NAME";\n'
        '}',
        INTERFACE_NAME=interface_name,
        PARAMETERS=constructor_info.ParametersImplementationDeclaration(),
        IMPL_CLASS=implementation_class,
        IMPL_FUNCTION=implementation_function,
        NATIVE_NAME=native_implementation_function)

  def FinishInterface(self):
    base = self._BaseClassName()
    self._dart_impl_emitter.Emit(
        self._templates.Load('dart_implementation.darttemplate'),
        CLASS=self._class_name, BASE=base, INTERFACE=self._interface.id,
        MEMBERS=self._members_emitter.Fragments())

    self._GenerateCppHeader()

    self._cpp_impl_emitter.Emit(
        self._templates.Load('cpp_implementation.template'),
        INTERFACE=self._interface.id,
        INCLUDES=_GenerateCPPIncludes(self._cpp_impl_includes),
        CALLBACKS=self._cpp_definitions_emitter.Fragments(),
        RESOLVER=self._cpp_resolver_emitter.Fragments())

  def _GenerateCppHeader(self):
    to_native_emitter = emitter.Emitter()
    if self._interface_type_info.custom_to_native():
      to_native_emitter.Emit(
          '    static PassRefPtr<NativeType> toNative(Dart_Handle handle, Dart_Handle& exception);\n')
    else:
      to_native_emitter.Emit(
          '    static NativeType* toNative(Dart_Handle handle, Dart_Handle& exception)\n'
          '    {\n'
          '        return DartDOMWrapper::unwrapDartWrapper<Dart$INTERFACE>(handle, exception);\n'
          '    }\n',
          INTERFACE=self._interface.id)

    to_dart_emitter = emitter.Emitter()
    if ('CustomToJS' in self._interface.ext_attrs or
        'CustomToJSObject' in self._interface.ext_attrs or
        'PureInterface' in self._interface.ext_attrs or
        'CPPPureInterface' in self._interface.ext_attrs or
        self._interface_type_info.custom_to_dart()):
      to_dart_emitter.Emit(
          '    static Dart_Handle toDart(NativeType* value);\n')
    else:
      to_dart_emitter.Emit(
          '    static Dart_Handle toDart(NativeType* value)\n'
          '    {\n'
          '        return DartDOMWrapper::toDart<Dart$(INTERFACE)>(value);\n'
          '    }\n',
          INTERFACE=self._interface.id)

    webcore_includes = _GenerateCPPIncludes(self._interface_type_info.webcore_includes())
    wrapper_type = _DOMWrapperType(self._system._database, self._interface)
    self._cpp_header_emitter.Emit(
        self._templates.Load('cpp_header.template'),
        INTERFACE=self._interface.id,
        WEBCORE_INCLUDES=webcore_includes,
        WEBCORE_CLASS_NAME=self._interface_type_info.native_type(),
        DECLARATIONS=self._cpp_declarations_emitter.Fragments(),
        NATIVE_TRAITS_TYPE='DartDOMWrapper::%sTraits' % wrapper_type,
        TO_NATIVE=to_native_emitter.Fragments(),
        TO_DART=to_dart_emitter.Fragments())

  def _GenerateCallWithHandling(self, node, parameter_definitions_emitter, arguments):
    if 'CallWith' not in node.ext_attrs:
      return False

    call_with = node.ext_attrs['CallWith']
    if call_with == 'ScriptExecutionContext':
      parameter_definitions_emitter.Emit(
          '\n'
          '        ScriptExecutionContext* context = DartUtilities::scriptExecutionContext();\n'
          '        if (!context)\n'
          '            return;\n')
      arguments.append('context')
      return False

    if call_with == 'ScriptArguments|CallStack':
      self._cpp_impl_includes.add('"DOMWindow.h"')
      self._cpp_impl_includes.add('"ScriptArguments.h"')
      self._cpp_impl_includes.add('"ScriptCallStack.h"')
      self._cpp_impl_includes.add('"V8Proxy.h"')
      self._cpp_impl_includes.add('"v8.h"')
      parameter_definitions_emitter.Emit(
          '\n'
          '        v8::HandleScope handleScope;\n'
          '        v8::Context::Scope scope(V8Proxy::mainWorldContext(DartUtilities::domWindowForCurrentIsolate()->frame()));\n'
          '        Dart_Handle customArgument = Dart_GetNativeArgument(args, $INDEX);\n'
          '        RefPtr<ScriptArguments> scriptArguments(DartUtilities::createScriptArguments(customArgument, exception));\n'
          '        if (!scriptArguments)\n'
          '            goto fail;\n'
          '        RefPtr<ScriptCallStack> scriptCallStack(DartUtilities::createScriptCallStack());\n'
          '        if (!scriptCallStack->size())\n'
          '            return;\n',
          INDEX=len(node.arguments))
      arguments.extend(['scriptArguments', 'scriptCallStack'])
      return True

    return False

  def AddConstant(self, constant):
    # Constants are already defined on the interface.
    pass

  def AddAttribute(self, getter, setter):
    if 'CheckSecurityForNode' in (getter or setter).ext_attrs:
      # FIXME: exclude from interface as well.
      return

    if getter:
      self._AddGetter(getter)
    if setter:
      self._AddSetter(setter)

  def AddSecondaryAttribute(self, interface, getter, setter):
    self.AddAttribute(getter, setter)

  def _AddGetter(self, attr):
    type_info = GetIDLTypeInfo(attr.type.id)
    dart_declaration = '%s get %s()' % (
        type_info.dart_type(), DartDomNameOfAttribute(attr))
    is_custom = 'Custom' in attr.ext_attrs or 'CustomGetter' in attr.ext_attrs
    cpp_callback_name = self._GenerateNativeBinding(attr.id, 1,
        dart_declaration, 'Getter', is_custom)
    if is_custom:
      return

    arguments = []
    parameter_definitions_emitter = emitter.Emitter()
    raises_exceptions = self._GenerateCallWithHandling(attr, parameter_definitions_emitter, arguments)
    raises_exceptions = raises_exceptions or attr.get_raises

    if 'Reflect' in attr.ext_attrs:
      webcore_function_name = GetIDLTypeInfo(attr.type.id).webcore_getter_name()
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

    function_expression = self._GenerateWebCoreFunctionExpression(webcore_function_name, attr)
    invocation = self._GenerateWebCoreInvocation(function_expression,
        arguments, attr.type.id, attr.ext_attrs, attr.get_raises)
    self._GenerateNativeCallback(cpp_callback_name, parameter_definitions_emitter.Fragments(),
        True, invocation, raises_exceptions=raises_exceptions)

  def _AddSetter(self, attr):
    type_info = GetIDLTypeInfo(attr.type.id)
    dart_declaration = 'void set %s(%s)' % (
        DartDomNameOfAttribute(attr), type_info.dart_type())
    is_custom = set(['Custom', 'CustomSetter', 'V8CustomSetter']) & set(attr.ext_attrs)
    cpp_callback_name = self._GenerateNativeBinding(attr.id, 2,
        dart_declaration, 'Setter', is_custom)
    if is_custom:
      return

    arguments = []
    parameter_definitions_emitter = emitter.Emitter()
    self._GenerateCallWithHandling(attr, parameter_definitions_emitter, arguments)

    if 'Reflect' in attr.ext_attrs:
      webcore_function_name = GetIDLTypeInfo(attr.type.id).webcore_setter_name()
      arguments.append(self._GenerateWebCoreReflectionAttributeName(attr))
    else:
      webcore_function_name = re.sub(r'^(xml(?=[A-Z])|\w)',
                                     lambda s: s.group(1).upper(),
                                     attr.id)
      webcore_function_name = 'set%s' % webcore_function_name
      if attr.type.id.startswith('SVGAnimated'):
        webcore_function_name += 'Animated'

    argument_expression = self._GenerateToNative(
        parameter_definitions_emitter, attr, 1, argument_name='value')
    arguments.append(argument_expression)

    parameter_definitions = parameter_definitions_emitter.Fragments()
    function_expression = self._GenerateWebCoreFunctionExpression(webcore_function_name, attr)
    invocation = self._GenerateWebCoreInvocation(function_expression,
        arguments, 'void', attr.ext_attrs, attr.set_raises)

    self._GenerateNativeCallback(cpp_callback_name, parameter_definitions_emitter.Fragments(),
        True, invocation, raises_exceptions=True)

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
    if self._HasNativeIndexGetter():
      self._EmitNativeIndexGetter(dart_element_type)
    else:
      self._members_emitter.Emit(
          '\n'
          '  $TYPE operator[](int index) {\n'
          '    return item(index);\n'
          '  }\n',
          TYPE=dart_element_type)

    if self._HasNativeIndexSetter():
      self._EmitNativeIndexSetter(dart_element_type)
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

  def AmendIndexer(self, element_type):
    # If interface is marked as having native indexed
    # getter or setter, we must emit overrides as it's not
    # guaranteed that the corresponding methods in C++ would be
    # virtual.  For example, as of time of writing, even though
    # Uint8ClampedArray inherits from Uint8Array, ::set method
    # is not virtual and accessing it through Uint8Array pointer
    # would lead to wrong semantics (modulo vs. clamping.)
    dart_element_type = DartType(element_type)

    if self._HasNativeIndexGetter():
      self._EmitNativeIndexGetter(dart_element_type)
    if self._HasNativeIndexSetter():
      self._EmitNativeIndexSetter(dart_element_type)

  def _HasNativeIndexGetter(self):
    ext_attrs = self._interface.ext_attrs
    return ('CustomIndexedGetter' in ext_attrs or
        'NumericIndexedGetter' in ext_attrs)

  def _EmitNativeIndexGetter(self, element_type):
    dart_declaration = '%s operator[](int index)' % element_type
    self._GenerateNativeBinding('numericIndexGetter', 2, dart_declaration,
        'Callback', True)

  def _HasNativeIndexSetter(self):
    return 'CustomIndexedSetter' in self._interface.ext_attrs

  def _EmitNativeIndexSetter(self, element_type):
    dart_declaration = 'void operator[]=(int index, %s value)' % element_type
    self._GenerateNativeBinding('numericIndexSetter', 3, dart_declaration,
        'Callback', True)

  def _AddOperation(self, info):
    """
    Arguments:
      info: An OperationInfo object.
    """

    if 'CheckSecurityForNode' in info.overloads[0].ext_attrs:
      # FIXME: exclude from interface as well.
      return

    if 'Custom' in info.overloads[0].ext_attrs:
      parameters = info.ParametersImplementationDeclaration()
      dart_declaration = '%s %s(%s)' % (info.type_name, info.name, parameters)
      argument_count = (0 if info.IsStatic() else 1) + len(info.param_infos)
      self._GenerateNativeBinding(info.name, argument_count, dart_declaration,
          'Callback', True)
      return

    modifier = ''
    if info.IsStatic():
      modifier = 'static '
    body = self._members_emitter.Emit(
        '\n'
        '  $MODIFIER$TYPE $NAME($PARAMETERS) {\n'
        '$!BODY'
        '  }\n',
        MODIFIER=modifier,
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

  def AddOperation(self, info):
    self._AddOperation(info)

  def AddStaticOperation(self, info):
    self._AddOperation(info)

  def AddSecondaryOperation(self, interface, info):
    self.AddOperation(info)

  def GenerateSingleOperation(self,  dispatch_emitter, info, indent, operation):
    """Generates a call to a single operation.

    Arguments:
      dispatch_emitter: an dispatch_emitter for the body of a block of code.
      info: the compound information about the operation and its overloads.
      indent: an indentation string for generated code.
      operation: the IDLOperation to call.
    """

    self._native_version += 1
    native_name = info.name
    if self._native_version > 1:
      native_name = '%s_%s' % (native_name, self._native_version)
    argument_list = ', '.join([info.param_infos[i].name
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
    modifier = ''
    if operation.is_static:
      modifier = 'static '
    dart_declaration = '%s%s _%s(%s)' % (modifier, info.type_name, native_name,
                                       argument_list)
    is_custom = 'Custom' in operation.ext_attrs
    cpp_callback_name = self._GenerateNativeBinding(
        native_name, (0 if operation.is_static else 1) + len(operation.arguments), dart_declaration, 'Callback',
        is_custom)
    if is_custom:
      return

    # Generate callback.
    webcore_function_name = operation.ext_attrs.get('ImplementedAs', operation.id)

    parameter_definitions_emitter = emitter.Emitter()
    arguments = []
    raises_exceptions = self._GenerateCallWithHandling(
        operation, parameter_definitions_emitter, arguments)
    raises_exceptions = raises_exceptions or len(operation.arguments) > 0 or operation.raises

    # Process Dart arguments.
    start_index = 1
    if operation.is_static:
      start_index = 0
    for (i, argument) in enumerate(operation.arguments):
      if (i == len(operation.arguments) - 1 and
          self._interface.id == 'Console' and
          argument.id == 'arg'):
        # FIXME: we are skipping last argument here because it was added in
        # supplemental dart.idl. Cleanup dart.idl and remove this check.
        break
      argument_expression = self._GenerateToNative(
          parameter_definitions_emitter, argument, start_index + i)
      arguments.append(argument_expression)

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
      arguments.append('DartUtilities::processingUserGesture')

    function_expression = self._GenerateWebCoreFunctionExpression(webcore_function_name, operation)
    invocation = self._GenerateWebCoreInvocation(function_expression, arguments,
        operation.type.id, operation.ext_attrs, operation.raises)
    self._GenerateNativeCallback(cpp_callback_name,
        parameter_definitions=parameter_definitions_emitter.Fragments(),
        needs_receiver=not operation.is_static, invocation=invocation,
        raises_exceptions=raises_exceptions)

  def _GenerateNativeCallback(self, callback_name, parameter_definitions,
      needs_receiver, invocation, raises_exceptions):

    if needs_receiver:
      parameter_definitions = emitter.Format(
          '        $WEBCORE_CLASS_NAME* receiver = DartDOMWrapper::receiver< $WEBCORE_CLASS_NAME >(args);\n'
          '        $PARAMETER_DEFINITIONS\n',
          WEBCORE_CLASS_NAME=self._interface_type_info.native_type(),
          PARAMETER_DEFINITIONS=parameter_definitions)

    body = emitter.Format(
        '    {\n'
        '$PARAMETER_DEFINITIONS'
        '$INVOCATION'
        '        return;\n'
        '    }\n',
        PARAMETER_DEFINITIONS=parameter_definitions,
        INVOCATION=invocation)

    if raises_exceptions:
      body = emitter.Format(
          '    Dart_Handle exception = 0;\n'
          '$BODY'
          '\n'
          'fail:\n'
          '    Dart_ThrowException(exception);\n'
          '    ASSERT_NOT_REACHED();\n',
          BODY=body)

    self._cpp_definitions_emitter.Emit(
        '\n'
        'static void $CALLBACK_NAME(Dart_NativeArguments args)\n'
        '{\n'
        '    DartApiScope dartApiScope;\n'
        '$BODY'
        '}\n',
        CALLBACK_NAME=callback_name,
        BODY=body)

  def _GenerateToNative(self, emitter, idl_node, index,
                                argument_name=None):
    """idl_node is IDLArgument or IDLAttribute."""
    type_info = GetIDLTypeInfo(idl_node.type.id)
    if not IsPrimitiveType(idl_node.type.id):
      self._cpp_impl_includes.add('"Dart%s.h"' % type_info.idl_type())
    argument_name = argument_name or idl_node.id
    handle = 'Dart_GetNativeArgument(args, %i)' % index
    return type_info.emit_to_native(emitter, idl_node, argument_name, handle, self._interface.id)

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
    self._cpp_impl_includes.add('"%s.h"' % namespace)

    attribute_name = attr.ext_attrs['Reflect'] or attr.id.lower()
    return 'WebCore::%s::%sAttr' % (namespace, attribute_name)

  def _GenerateWebCoreFunctionExpression(self, function_name, idl_node):
    if 'ImplementedBy' in idl_node.ext_attrs:
      return '%s::%s' % (idl_node.ext_attrs['ImplementedBy'], function_name)
    if idl_node.is_static:
      return '%s::%s' % (self._interface_type_info.idl_type(), function_name)
    return '%s%s' % (self._interface_type_info.receiver(), function_name)

  def _GenerateWebCoreInvocation(self, function_expression, arguments,
      idl_return_type, attributes, raises_dom_exceptions):
    invocation_template = '        $FUNCTION_CALL;\n'
    if idl_return_type != 'void':
      return_type_info = GetIDLTypeInfo(idl_return_type)
      self._cpp_impl_includes |= set(return_type_info.conversion_includes())

      # Generate to Dart conversion of C++ value.
      to_dart_conversion = return_type_info.to_dart_conversion('$FUNCTION_CALL', self._interface.id, attributes)
      invocation_template = emitter.Format(
          '        Dart_Handle returnValue = $TO_DART_CONVERSION;\n'
          '        if (returnValue)\n'
          '            Dart_SetReturnValue(args, returnValue);\n',
          TO_DART_CONVERSION=to_dart_conversion)

    if raises_dom_exceptions:
      # Add 'ec' argument to WebCore invocation and convert DOM exception to Dart exception.
      arguments.append('ec')
      invocation_template = emitter.Format(
          '        ExceptionCode ec = 0;\n'
          '$INVOCATION'
          '        if (UNLIKELY(ec)) {\n'
          '            exception = DartDOMWrapper::exceptionCodeToDartException(ec);\n'
          '            goto fail;\n'
          '        }\n',
          INVOCATION=invocation_template)

    if 'ImplementedBy' in attributes:
      arguments.insert(0, 'receiver')
      self._cpp_impl_includes.add('"%s.h"' % attributes['ImplementedBy'])

    return emitter.Format(invocation_template,
        FUNCTION_CALL='%s(%s)' % (function_expression, ', '.join(arguments)))

def _GenerateCPPIncludes(includes):
  return ''.join(['#include %s\n' % include for include in includes])

def _DOMWrapperType(database, interface):
  if interface.id == 'MessagePort':
    return 'MessagePort'

  type = 'Object'
  def is_node(interface):
    return interface.id == 'Node'
  if is_node(interface) or _FindParent(interface, database, is_node):
    type = 'Node'
  if 'ActiveDOMObject' in interface.ext_attrs:
    type = 'Active%s' % type
  return type

def _FindParent(interface, database, callback):
  for parent in interface.parents:
    parent_name = parent.type.id
    if not database.HasInterface(parent.type.id):
      continue
    parent_interface = database.GetInterface(parent.type.id)
    if callback(parent_interface):
      return parent_interface
    parent_interface = _FindParent(parent_interface, database, callback)
    if parent_interface:
      return parent_interface
