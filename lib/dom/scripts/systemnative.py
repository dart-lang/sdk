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
from systemhtml import DomToHtmlEvent, DomToHtmlEvents, HtmlSystemShared
from systemhtml import HtmlElementConstructorInfos
from systemhtml import EmitHtmlElementFactoryConstructors

class NativeImplementationSystem(System):

  def __init__(self, templates, database, html_database, html_renames,
               emitters, output_dir):
    super(NativeImplementationSystem, self).__init__(
        templates, database, emitters, output_dir)

    self._html_renames = html_renames
    self._dom_impl_files = []
    self._cpp_header_files = []
    self._cpp_impl_files = []
    self._html_system = HtmlSystemShared(html_database)
    self._factory_provider_emitters = {}

  def InterfaceGenerator(self,
                         interface,
                         common_prefix,
                         super_interface_name,
                         source_filter):
    interface_name = interface.id

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

  def _FilePathForDartImplementation(self, interface_name):
    return os.path.join(self._output_dir, 'dart',
                        '%sImplementation.dart' % interface_name)

  def _FilePathForDartFactoryProviderImplementation(self, interface_name):
    return os.path.join(self._output_dir, 'dart',
                        '%sFactoryProviderImplementation.dart' % interface_name)

  def _FilePathForCppHeader(self, interface_name):
    return os.path.join(self._output_dir, 'cpp', 'Dart%s.h' % interface_name)

  def _FilePathForCppImplementation(self, interface_name):
    return os.path.join(self._output_dir, 'cpp', 'Dart%s.cpp' % interface_name)

  def _EmitterForFactoryProviderBody(self, name):
    if name not in self._factory_provider_emitters:
      file_name = self._FilePathForDartFactoryProviderImplementation(name)
      self._dom_impl_files.append(file_name)
      template = self._templates.Load('factoryprovider_%s.darttemplate' % name)
      file_emitter = self._emitters.FileEmitter(file_name)
      self._factory_provider_emitters[name] = file_emitter.Emit(template)
    return self._factory_provider_emitters[name]

  def DartImplementationFiles(self):
    return self._dom_impl_files


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
    self._html_system = self._system._html_system

  def StartInterface(self):
    self._interface_type_info = GetIDLTypeInfo(self._interface.id)
    self._members_emitter = emitter.Emitter()
    self._cpp_declarations_emitter = emitter.Emitter()
    self._cpp_impl_includes = set()
    self._cpp_definitions_emitter = emitter.Emitter()
    self._cpp_resolver_emitter = emitter.Emitter()

    self._GenerateConstructors()
    self._GenerateEvents()

  def _GenerateConstructors(self):
    html_interface_name = self._HTMLInterfaceName(self._interface.id)
    infos = HtmlElementConstructorInfos(html_interface_name)
    if infos:
      self._EmitHtmlElementFactoryConstructors(infos, html_interface_name)

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

  def _EmitHtmlElementFactoryConstructors(self, infos, html_interface_name):
    EmitHtmlElementFactoryConstructors(
        self._system._EmitterForFactoryProviderBody(
            infos[0].factory_provider_name),
        infos,
        html_interface_name,
        html_interface_name)

  def _GenerateEvents(self):
    if self._interface.id == 'DocumentFragment':
      # Interface DocumentFragment extends Element in dart:html but this fact
      # is not reflected in idls.
      self._EmitEventGetter('_ElementEventsImpl')
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
      self._members_emitter.Emit('  _EventsImpl _on;\n')

    if not events_attributes:
      if is_root:
        self._EmitEventGetter('_EventsImpl')
      return

    events_class = '_%sEventsImpl' % self._interface.id
    self._EmitEventGetter(events_class)

    def HasEventAttributes(interface):
      return any([a.type.id == 'EventListener' for a in interface.attributes])
    parent = _FindParent(self._interface, self._system._database, HasEventAttributes)
    if parent:
      parent_events_class = '_%sEventsImpl' % parent.id
    else:
      parent_events_class = '_EventsImpl'

    html_inteface = self._HTMLInterfaceName(self._interface.id)
    events_members = self._dart_impl_emitter.Emit(
        '\n'
        'class $EVENTS_CLASS extends $PARENT_EVENTS_CLASS implements $EVENTS_INTERFACE {\n'
        '  $EVENTS_CLASS(_ptr) : super(_ptr);\n'
        '$!MEMBERS\n'
        '}\n',
        EVENTS_CLASS=events_class,
        PARENT_EVENTS_CLASS=parent_events_class,
        EVENTS_INTERFACE='%sEvents' % html_inteface)

    events_attributes = DomToHtmlEvents(self._interface.id, events_attributes)
    for event_name in events_attributes:
      events_members.Emit(
          '  EventListenerList get $HTML_NAME() => _get(\'$DOM_NAME\');\n',
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
    return '_%sImpl' % interface_name

  def _DartType(self, idl_type):
    type_info = GetIDLTypeInfo(idl_type)
    return self._HTMLInterfaceName(type_info.dart_type())

  def _BaseClassName(self):
    if not self._interface.parents:
      return '_DOMWrapperBase'

    supertype = self._interface.parents[0].type.id

    # FIXME: We're currently injecting List<..> and EventTarget as
    # supertypes in dart.idl. We should annotate/preserve as
    # attributes instead.  For now, this hack lets the self._interfaces
    # inherit, but not the classes.
    # List methods are injected in AddIndexer.
    if IsDartListType(supertype) or IsDartCollectionType(supertype):
      return '_DOMWrapperBase'

    if supertype == 'EventTarget':
      # Most implementors of EventTarget specify the EventListener operations
      # again.  If the operations are not specified, try to inherit from the
      # EventTarget implementation.
      #
      # Applies to MessagePort.
      if not [op for op in self._interface.operations if op.id == 'addEventListener']:
        return self._ImplClassName(supertype)
      return '_DOMWrapperBase'

    return self._ImplClassName(supertype)

  def _HTMLInterfaceName(self, interface_name):
    return self._system._html_renames.get(interface_name, interface_name)

  def _IsConstructable(self):
    # FIXME: support ConstructorTemplate.
    return set(['CustomConstructor', 'V8CustomConstructor', 'Constructor', 'NamedConstructor']) & set(self._interface.ext_attrs)

  def _EmitFactoryProvider(self, interface_name, constructor_info):
    dart_impl_path = self._system._FilePathForDartFactoryProviderImplementation(
        interface_name)
    self._system._dom_impl_files.append(dart_impl_path)

    html_interface_name = self._HTMLInterfaceName(interface_name)
    template_file = 'factoryprovider_%s.darttemplate' % html_interface_name
    template = self._system._templates.TryLoad(template_file)
    if not template:
      template = self._system._templates.Load('factoryprovider.darttemplate')

    native_implementation_function = '%s_constructor_Callback' % interface_name
    emitter = self._system._emitters.FileEmitter(dart_impl_path)
    emitter.Emit(
        template,
        FACTORYPROVIDER='_%sFactoryProvider' % html_interface_name,
        INTERFACE=html_interface_name,
        PARAMETERS=constructor_info.ParametersImplementationDeclaration(self._DartType),
        ARGUMENTS=constructor_info.ParametersAsArgumentList(),
        NATIVE_NAME=native_implementation_function)

  def FinishInterface(self):
    html_interface_name = self._HTMLInterfaceName(self._interface.id)
    template = None
    if html_interface_name == self._interface.id or not self._system._database.HasInterface(html_interface_name):
      template_file = 'impl_%s.darttemplate' % html_interface_name
      template = self._templates.TryLoad(template_file)
    if not template:
      template = self._templates.Load('dart_implementation.darttemplate')

    class_name = self._ImplClassName(self._interface.id)
    members_emitter = self._dart_impl_emitter.Emit(
        template,
        CLASSNAME=class_name,
        EXTENDS=' extends ' + self._BaseClassName(),
        IMPLEMENTS=' implements ' + html_interface_name,
        NATIVESPEC='')
    members_emitter.Emit(''.join(self._members_emitter.Fragments()))

    self._GenerateCppHeader()

    self._cpp_impl_emitter.Emit(
        self._templates.Load('cpp_implementation.template'),
        INTERFACE=self._interface.id,
        INCLUDES=_GenerateCPPIncludes(self._cpp_impl_includes),
        CALLBACKS=self._cpp_definitions_emitter.Fragments(),
        RESOLVER=self._cpp_resolver_emitter.Fragments(),
        DART_IMPLEMENTATION_CLASS=class_name)

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

    html_interface_name = self._HTMLInterfaceName(self._interface.id)
    dom_name = DartDomNameOfAttribute(getter or setter)
    html_getter_name = self._html_system.RenameInHtmlLibrary(
        html_interface_name, dom_name, 'get:', implementation_class=True)
    html_setter_name = self._html_system.RenameInHtmlLibrary(
        html_interface_name, dom_name, 'set:', implementation_class=True)

    if getter and html_getter_name:
      self._AddGetter(getter, html_getter_name)
    if setter and html_setter_name:
      self._AddSetter(setter, html_setter_name)

  def AddSecondaryAttribute(self, interface, getter, setter):
    self.AddAttribute(getter, setter)

  def _AddGetter(self, attr, html_name):
    type_info = GetIDLTypeInfo(attr.type.id)
    dart_declaration = '%s get %s()' % (self._DartType(attr.type.id), html_name)
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

  def _AddSetter(self, attr, html_name):
    type_info = GetIDLTypeInfo(attr.type.id)
    dart_declaration = 'void set %s(%s)' % (html_name, self._DartType(attr.type.id))
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
    dart_element_type = self._DartType(element_type)
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
      # The HTML library implementation of NodeList has a custom indexed setter
      # implementation that uses the parent node the NodeList is associated
      # with if one is available.
      if self._interface.id != 'NodeList':
        self._members_emitter.Emit(
            '\n'
            '  void operator[]=(int index, $TYPE value) {\n'
            '    throw new UnsupportedOperationException("Cannot assign element of immutable List.");\n'
            '  }\n',
            TYPE=dart_element_type)

    # The list interface for this class is manually generated.
    if self._interface.id == 'NodeList':
      return

    # TODO(sra): Use separate mixins for mutable implementations of List<T>.
    # TODO(sra): Use separate mixins for typed array implementations of List<T>.
    template_file = 'immutable_list_mixin.darttemplate'
    template = self._system._templates.Load(template_file)
    self._members_emitter.Emit(template, E=dart_element_type)

  def AmendIndexer(self, element_type):
    # If interface is marked as having native indexed
    # getter or setter, we must emit overrides as it's not
    # guaranteed that the corresponding methods in C++ would be
    # virtual.  For example, as of time of writing, even though
    # Uint8ClampedArray inherits from Uint8Array, ::set method
    # is not virtual and accessing it through Uint8Array pointer
    # would lead to wrong semantics (modulo vs. clamping.)
    dart_element_type = self._DartType(element_type)

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

    html_interface_name = self._HTMLInterfaceName(self._interface.id)
    html_name = self._html_system.RenameInHtmlLibrary(
        html_interface_name, info.name, implementation_class=True)

    if not html_name and info.name == 'item':
      # FIXME: item should be renamed to operator[], not removed.
      html_name = 'item'

    if not html_name:
      return

    dart_declaration = '%s%s %s(%s)' % (
        'static ' if info.IsStatic() else '',
        self._DartType(info.type_name),
        html_name or info.name,
        info.ParametersImplementationDeclaration(self._DartType))

    if 'Custom' in info.overloads[0].ext_attrs:
      argument_count = (0 if info.IsStatic() else 1) + len(info.param_infos)
      self._GenerateNativeBinding(info.name , argument_count,
          dart_declaration, 'Callback', True)
      return

    if self._interface.id == 'Document' and info.name == 'querySelector':
      # Document.querySelector has custom implementation in dart:html.
      # FIXME: Cleanup query selectors and remove this hack.
      body = emitter.Emitter()
    else:
      body = self._members_emitter.Emit(
          '\n'
          '  $DECLARATION {\n'
          '$!BODY'
          '  }\n',
          DECLARATION=dart_declaration)

    self._native_version = 0
    overloads = self.CombineOverloads(info.overloads)
    fallthrough = self.GenerateDispatch(body, info, '    ', overloads)
    if fallthrough:
      body.Emit('    throw "Incorrect number or type of arguments";\n');

  def CombineOverloads(self, overloads):
    # Combine overloads that can be implemented by the same native method.  This
    # undoes the expansion of optional arguments into multiple overloads unless
    # IDL merging has made the overloads necessary.  Starting with overload with
    # no optional arguments and grow it by adding optional arguments, then the
    # longest overload can serve for all the shorter ones.
    out = []
    seed_index = 0
    while seed_index < len(overloads):
      seed = overloads[seed_index]
      if len(seed.arguments) > 0 and seed.arguments[-1].is_optional:
        # Must start with no optional arguments.
        out.append(seed)
        seed_index += 1
        continue

      prev = seed
      probe_index = seed_index + 1
      while probe_index < len(overloads):
        probe = overloads[probe_index]
        # Check that 'probe' extends 'prev' by one optional argument.
        if len(probe.arguments) != len(prev.arguments) + 1:
          break
        if probe.arguments[:-1] != prev.arguments:
          break
        if not probe.arguments[-1].is_optional:
          break
        # See Issue 3177.  This test against known implemented types is to
        # prevent combining a possibly unimplemented type.  Combining with an
        # unimplemented type will cause all set of combined overloads to become
        # 'unimplemented', even if no argument is passed to the the
        # unimplemented parameter.
        if DartType(probe.arguments[-1].type.id) not in [
            'String', 'int', 'num', 'double', 'bool',
            'IDBKeyRange']:
          break
        probe_index += 1
        prev = probe
      out.append(prev)
      seed_index = probe_index

    return out

  def PrintOverloadsComment(self, emitter, info, indent, note, overloads):
    emitter.Emit('$(INDENT)//$NOTE\n', INDENT=indent, NOTE=note)
    for operation in overloads:
      params = ', '.join([
          ('[Optional] ' if arg.is_optional else '') + DartType(arg.type.id) + ' '
          + arg.id for arg in operation.arguments])
      emitter.Emit('$(INDENT)// $NAME($PARAMS)\n',
                   INDENT=indent,
                   NAME=info.name,
                   PARAMS=params)
    emitter.Emit('$(INDENT)//\n', INDENT=indent)

  def GenerateDispatch(self, emitter, info, indent, overloads):
    """Generates a dispatch to one of the overloads.

    Arguments:
      emitter: an Emitter for the body of a block of code.
      info: the compound information about the operation and its overloads.
      indent: an indentation string for generated code.
      position: the index of the parameter to dispatch on.
      overloads: a list of the IDLOperations to dispatch.

    Returns True if the dispatch can fall through on failure, False if the code
    always dispatches.
    """

    def NullCheck(name):
      return '%s === null' % name

    def TypeCheck(name, type):
      return '%s is %s' % (name, type)

    def IsNullable(type):
      #return type != 'int' and type != 'num'
      return True

    def PickRequiredCppSingleOperation():
      # Returns a special case single operation, or None.  Check if we dispatch
      # on RequiredCppParameter arguments.  In this case all trailing arguments
      # must be RequiredCppParameter and there is no need in dispatch.
      def IsRequiredCppParameter(arg):
        return 'RequiredCppParameter' in arg.ext_attrs
      def HasRequiredCppParameters(op):
        matches = filter(IsRequiredCppParameter, op.arguments)
        if matches:
          # Validate all the RequiredCppParameter ones are at the end.
          rematches = filter(IsRequiredCppParameter,
                             op.arguments[len(op.arguments) - len(matches):])
          if len(matches) != len(rematches):
            raise Exception('Invalid RequiredCppParameter - all subsequent '
                            'parameters must also be RequiredCppParameter.')
          return True
        return False
      if any(HasRequiredCppParameters(op) for op in overloads):
        longest = max(overloads, key=lambda op: len(op.arguments))
        # Validate all other overloads are prefixes.
        for op in overloads:
          for (index, arg) in enumerate(op.arguments):
            type1 = arg.type.id
            type2 = longest.arguments[index].type.id
            if type1 != type2:
              raise Exception(
                  'Overloads for method %s with RequiredCppParameter have '
                  'inconsistent types %s and %s for parameter #%s' %
                  (info.name, type1, type2, index))
        return longest
      return None

    single_operation = PickRequiredCppSingleOperation()
    if single_operation:
      self.GenerateSingleOperation(emitter, info, indent, single_operation)
      return False

    # Print just the interesting sets of overloads.
    if len(overloads) > 1 or len(info.overloads) > 1:
      self.PrintOverloadsComment(emitter, info, indent, '', info.overloads)
      if overloads != info.overloads:
        self.PrintOverloadsComment(emitter, info, indent, ' -- reduced:',
                                   overloads)

    # Match each operation in turn.
    # TODO: Optimize the dispatch to avoid repeated tests.
    fallthrough = True
    for operation in overloads:
      tests = []
      for (position, param) in enumerate(info.param_infos):
        if position < len(operation.arguments):
          arg = operation.arguments[position]
          dart_type = self._DartType(arg.type.id)
          if dart_type == param.dart_type:
            # The overload type matches the method parameter type exactly.  We
            # will have already tested this type in checked mode, and the target
            # will expect (i.e. check) this type.  This case happens when all
            # the overloads have the same type in this position, including the
            # trivial case of one overload.
            test = None
          else:
            test = TypeCheck(param.name, dart_type)
            if IsNullable(dart_type) or arg.is_optional:
              test = '(%s || %s)' % (NullCheck(param.name), test)
        else:
          test = NullCheck(param.name)
        if test:
          tests.append(test)
      if tests:
        cond = ' && '.join(tests)
        if len(cond) + len(indent) + 7 > 80:
          cond = (' &&\n' + indent + '    ').join(tests)
        call = emitter.Emit(
            '$(INDENT)if ($COND) {\n'
            '$!CALL'
            '$(INDENT)}\n',
            COND=cond,
            INDENT=indent)
        self.GenerateSingleOperation(call, info, indent + '  ', operation)
      else:
        self.GenerateSingleOperation(emitter, info, indent, operation)
        fallthrough = False
    return fallthrough

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
    dart_declaration = '%s%s _%s(%s)' % (modifier, self._DartType(info.type_name), native_name,
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
