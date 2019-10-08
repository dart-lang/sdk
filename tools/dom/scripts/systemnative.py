#!/usr/bin/python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
"""This module provides shared functionality for the systems to generate
native binding from the IDL database."""

import emitter
import logging
import os
from generator import *
from htmldartgenerator import *
from idlnode import IDLArgument, IDLAttribute, IDLEnum, IDLMember
from systemhtml import js_support_checks, GetCallbackInfo, HTML_LIBRARY_NAMES

_logger = logging.getLogger('systemnative')

# TODO(vsm): This should be recoverable from IDL, but we appear to not
# track the necessary info.
_url_utils = [
    'hash', 'host', 'hostname', 'origin', 'password', 'pathname', 'port',
    'protocol', 'search', 'username'
]

_promise_to_future = Conversion('promiseToFuture', 'dynamic', 'Future')


def array_type(data_type):
    matched = re.match(r'([\w\d_\s]+)\[\]', data_type)
    if not matched:
        return None
    return matched.group(1)


_sequence_matcher = re.compile('sequence\<(.+)\>')


def TypeIdToBlinkName(interface_id, database):
    # Maybe should use the type_registry here?
    if database.HasEnum(interface_id):
        return "DOMString"  # All enums are strings.

    seq_match = _sequence_matcher.match(interface_id)
    if seq_match is not None:
        t = TypeIdToBlinkName(seq_match.group(1), database)
        return "sequence<%s>" % t

    arr_match = array_type(interface_id)
    if arr_match is not None:
        t = TypeIdToBlinkName(arr_match, database)
        return "%s[]" % t

    return interface_id


def DeriveQualifiedName(library_name, name):
    return library_name + "." + name


def DeriveBlinkClassName(name):
    return "Blink" + name


_type_encoding_map = {
    'long long': "ll",
    'unsigned long': "ul",
    'unsigned long long': "ull",
    'unsigned short': "us",
}


def EncodeType(t):

    seq_match = _sequence_matcher.match(t)
    if seq_match is not None:
        t2 = EncodeType(seq_match.group(1))
        t = "SEQ_%s_SEQ" % t2
        return t

    arr_match = array_type(t)
    if arr_match is not None:
        t = EncodeType(arr_match)
        return "A_%s_A" % t

    return _type_encoding_map.get(t) or t


class DartiumBackend(HtmlDartGenerator):
    """Generates Dart implementation for one DOM IDL interface."""

    def __init__(self, interface, cpp_library_emitter, options, loggerParent):
        super(DartiumBackend, self).__init__(interface, options, True,
                                             loggerParent)

        self._interface = interface
        self._cpp_library_emitter = cpp_library_emitter
        self._database = options.database
        self._template_loader = options.templates
        self._type_registry = options.type_registry
        self._interface_type_info = self._type_registry.TypeInfo(
            self._interface.id)
        self._metadata = options.metadata
        # These get initialized by StartInterface
        self._cpp_header_emitter = None
        self._cpp_impl_emitter = None
        self._members_emitter = None
        self._cpp_declarations_emitter = None
        self._cpp_impl_includes = None
        self._cpp_definitions_emitter = None
        self._cpp_resolver_emitter = None
        self._dart_js_interop = options.dart_js_interop
        _logger.setLevel(loggerParent.level)

    def ImplementsMergedMembers(self):
        # We could not add merged functions to implementation class because
        # underlying c++ object doesn't implement them. Merged functions are
        # generated on merged interface implementation instead.
        return False

    def CustomJSMembers(self):
        return {}

    def _OutputConversion(self, idl_type, member):
        conversion = FindConversion(idl_type, 'get', self._interface.id, member)
        # TODO(jacobr) handle promise consistently in dart2js and dartium.
        if idl_type == 'Promise':
            return _promise_to_future
        if conversion:
            if conversion.function_name in ('convertNativeToDart_DateTime',
                                            'convertNativeToDart_ImageData'):
                return None
        return conversion

    def _InputConversion(self, idl_type, member):
        return FindConversion(idl_type, 'set', self._interface.id, member)

    def GenerateCallback(self, info):
        return None

    def ImplementationTemplate(self):
        template = None
        interface_name = self._interface.doc_js_name
        if interface_name == self._interface.id or not self._database.HasInterface(
                interface_name):
            template_file = 'impl_%s.darttemplate' % interface_name
            template = self._template_loader.TryLoad(template_file)
        if not template:
            template = self._template_loader.Load(
                'dart_implementation.darttemplate')
        return template

    def RootClassName(self):
        return 'DartHtmlDomObject'

    # This code matches up with the _generate_native_entry code in
    # dart_utilities.py in the dartium repository.  Any changes to this
    # should have matching changes on that end.
    def DeriveNativeEntry(self, name, kind, count):
        interface_id = self._interface.id
        database = self._database
        tag = ""
        if kind == 'Getter':
            tag = "%s_Getter" % name
            blink_entry = tag
        elif kind == 'Setter':
            tag = "%s_Setter" % name
            blink_entry = tag
        elif kind == 'Constructor':
            tag = "constructorCallback"
            blink_entry = tag
        elif kind == 'Method':
            tag = "%s_Callback" % name
            blink_entry = tag

        interface_id = TypeIdToBlinkName(interface_id, database)

        def mkPublic(s):
            if s.startswith("_") or s.startswith("$"):
                return "$" + s
            return s

        if count is not None:
            arity = str(count)
            dart_name = mkPublic("_".join([tag, arity]))
        else:
            dart_name = mkPublic(tag)
        resolver_string = "_".join([interface_id, tag])

        return (dart_name, resolver_string)

    def DeriveNativeName(self, name, suffix=""):
        fields = ['$' + name]
        if suffix != "":
            fields.append(suffix)
        return "_".join(fields)

    def DeriveQualifiedBlinkName(self, interface_name, name):
        blinkClass = DeriveQualifiedName("_blink",
                                         DeriveBlinkClassName(interface_name))
        blinkInstance = DeriveQualifiedName(blinkClass, "instance")
        return DeriveQualifiedName(blinkInstance, name + "_")

    def NativeSpec(self):
        return ''

    def StartInterface(self, members_emitter):
        # Create emitters for c++ implementation.
        if not IsPureInterface(self._interface.id, self._database) and \
            not IsCustomType(self._interface.id):
            self._cpp_header_emitter = self._cpp_library_emitter.CreateHeaderEmitter(
                self._interface.id,
                self._renamer.GetLibraryName(self._interface))
            self._cpp_impl_emitter = \
              self._cpp_library_emitter.CreateSourceEmitter(self._interface.id)
        else:
            self._cpp_header_emitter = emitter.Emitter()
            self._cpp_impl_emitter = emitter.Emitter()

        self._interface_type_info = self._TypeInfo(self._interface.id)
        self._members_emitter = members_emitter

        self._cpp_declarations_emitter = emitter.Emitter()

        # This is a hack to work around a strange C++ compile error that we weren't
        # able to track down the true cause of.
        if self._interface.id == 'Timing':
            self._cpp_impl_includes.add('"core/animation/TimedItem.h"')

        self._cpp_definitions_emitter = emitter.Emitter()
        self._cpp_resolver_emitter = emitter.Emitter()

        # We need to revisit our treatment of typed arrays, right now
        # it is full of hacks.
        if self._interface.ext_attrs.get('ConstructorTemplate') == 'TypedArray':
            self._cpp_resolver_emitter.Emit(
                '    if (name == "$(INTERFACE_NAME)_constructor_Callback")\n'
                '        return Dart$(INTERFACE_NAME)Internal::constructorCallback;\n',
                INTERFACE_NAME=self._interface.id)

            self._cpp_impl_includes.add('"DartArrayBufferViewCustom.h"')
            self._cpp_definitions_emitter.Emit(
                '\n'
                'static void constructorCallback(Dart_NativeArguments args)\n'
                '{\n'
                '    WebCore::DartArrayBufferViewInternal::constructWebGLArray<Dart$(INTERFACE_NAME)>(args);\n'
                '}\n',
                INTERFACE_NAME=self._interface.id)

    def _EmitConstructorInfrastructure(self,
                                       constructor_info,
                                       cpp_prefix,
                                       cpp_suffix,
                                       factory_method_name,
                                       arguments=None,
                                       emit_to_native=False,
                                       is_custom=False):

        constructor_callback_cpp_name = cpp_prefix + cpp_suffix

        if arguments is None:
            arguments = constructor_info.idl_args[0]
            argument_count = len(arguments)
        else:
            argument_count = len(arguments)

        typed_formals = constructor_info.ParametersAsArgumentList(
            argument_count)
        parameters = constructor_info.ParametersAsStringOfVariables(
            argument_count)
        interface_name = self._interface_type_info.interface_name()

        dart_native_name, constructor_callback_id = \
            self.DeriveNativeEntry(cpp_suffix, 'Constructor', argument_count)

        # Then we emit the impedance matching wrapper to call out to the
        # toplevel wrapper
        if not emit_to_native:
            toplevel_name = \
                self.DeriveQualifiedBlinkName(self._interface.id,
                                              dart_native_name)
            self._members_emitter.Emit(
                '  static $INTERFACE_NAME $FACTORY_METHOD_NAME($PARAMETERS) => '
                '$TOPLEVEL_NAME($OUTPARAMETERS);\n',
                INTERFACE_NAME=self._interface_type_info.interface_name(),
                FACTORY_METHOD_NAME=factory_method_name,
                PARAMETERS=typed_formals,
                TOPLEVEL_NAME=toplevel_name,
                OUTPARAMETERS=parameters)

        self._cpp_resolver_emitter.Emit(
            '    if (name == "$ID")\n'
            '        return Dart$(WEBKIT_INTERFACE_NAME)Internal::$CPP_CALLBACK;\n',
            ID=constructor_callback_id,
            WEBKIT_INTERFACE_NAME=self._interface.id,
            CPP_CALLBACK=constructor_callback_cpp_name)

    def GenerateCustomFactory(self, constructor_info):
        if 'CustomConstructor' not in self._interface.ext_attrs:
            return False

        annotations = self._metadata.GetFormattedMetadata(
            self._library_name, self._interface, self._interface.id, '  ')

        self._members_emitter.Emit(
            '\n  $(ANNOTATIONS)factory $CTOR($PARAMS) => _create($FACTORY_PARAMS);\n',
            ANNOTATIONS=annotations,
            CTOR=constructor_info._ConstructorFullName(self._DartType),
            PARAMS=constructor_info.ParametersAsDeclaration(self._DartType),
            FACTORY_PARAMS= \
                constructor_info.ParametersAsArgumentList())

        # MutationObserver has custom _create.  TODO(terry): Consider table but this is only one.
        if self._interface.id != 'MutationObserver':
            constructor_callback_cpp_name = 'constructorCallback'
            self._EmitConstructorInfrastructure(
                constructor_info,
                "",
                constructor_callback_cpp_name,
                '_create',
                is_custom=True)

            self._cpp_declarations_emitter.Emit(
                '\n'
                'void $CPP_CALLBACK(Dart_NativeArguments);\n',
                CPP_CALLBACK=constructor_callback_cpp_name)

        return True

    def IsConstructorArgumentOptional(self, argument):
        return IsOptional(argument)

    def MakeFactoryCall(self, factory, method, arguments, constructor_info):
        return emitter.Format(
            '$FACTORY.$METHOD($ARGUMENTS)',
            FACTORY=factory,
            METHOD=method,
            ARGUMENTS=arguments)

    def EmitStaticFactoryOverload(self, constructor_info, name, arguments):
        constructor_callback_cpp_name = name + 'constructorCallback'
        self._EmitConstructorInfrastructure(
            constructor_info,
            name,
            'constructorCallback',
            name,
            arguments,
            emit_to_native=True,
            is_custom=False)

        ext_attrs = self._interface.ext_attrs

        create_function = 'create'
        if 'NamedConstructor' in ext_attrs:
            create_function = 'createForJSConstructor'
        function_expression = '%s::%s' % (
            self._interface_type_info.native_type(), create_function)

    def HasSupportCheck(self):
        # Need to omit a support check if it is conditional in JS.
        return self._interface.doc_js_name in js_support_checks

    def GetSupportCheck(self):
        # Assume that everything is supported on Dartium.
        value = js_support_checks.get(self._interface.doc_js_name)
        if type(value) == tuple:
            return (value[0], 'true')
        else:
            return 'true'

    def FinishInterface(self):
        interface = self._interface
        if interface.parents:
            supertype = '%sClassId' % interface.parents[0].type.id
        else:
            supertype = '-1'

        self._GenerateCPPHeader()

        self._cpp_impl_emitter.Emit(
            self._template_loader.Load('cpp_implementation.template'),
            INTERFACE=self._interface.id,
            SUPER_INTERFACE=supertype,
            INCLUDES=self._GenerateCPPIncludes(self._cpp_impl_includes),
            CALLBACKS=self._cpp_definitions_emitter.Fragments(),
            RESOLVER=self._cpp_resolver_emitter.Fragments(),
            WEBCORE_CLASS_NAME=self._interface_type_info.native_type(),
            WEBCORE_CLASS_NAME_ESCAPED=self._interface_type_info.native_type().
            replace('<', '_').replace('>', '_'),
            DART_IMPLEMENTATION_CLASS=self._interface_type_info.
            implementation_name(),
            DART_IMPLEMENTATION_LIBRARY_ID='Dart%sLibraryId' %
            self._renamer.GetLibraryId(self._interface))

    def _GenerateCPPHeader(self):
        to_native_emitter = emitter.Emitter()
        if self._interface_type_info.custom_to_native():
            return_type = 'PassRefPtr<NativeType>'
            to_native_body = ';'
            to_native_arg_body = ';'
        else:
            return_type = 'NativeType*'
            to_native_body = emitter.Format(
                '\n'
                '    {\n'
                '        DartDOMData* domData = DartDOMData::current();\n'
                '        return DartDOMWrapper::unwrapDartWrapper<Dart$INTERFACE>(domData, handle, exception);\n'
                '    }',
                INTERFACE=self._interface.id)
            to_native_arg_body = emitter.Format(
                '\n'
                '    {\n'
                '        return DartDOMWrapper::unwrapDartWrapper<Dart$INTERFACE>(args, index, exception);\n'
                '    }',
                INTERFACE=self._interface.id)

        to_native_emitter.Emit(
            '    static $RETURN_TYPE toNative(Dart_Handle handle, Dart_Handle& exception)$TO_NATIVE_BODY\n'
            '\n'
            '    static $RETURN_TYPE toNativeWithNullCheck(Dart_Handle handle, Dart_Handle& exception)\n'
            '    {\n'
            '        return Dart_IsNull(handle) ? 0 : toNative(handle, exception);\n'
            '    }\n'
            '\n'
            '    static $RETURN_TYPE toNative(Dart_NativeArguments args, int index, Dart_Handle& exception)$TO_NATIVE_ARG_BODY\n'
            '\n'
            '    static $RETURN_TYPE toNativeWithNullCheck(Dart_NativeArguments args, int index, Dart_Handle& exception)\n'
            '    {\n'
            '        // toNative accounts for Null objects also.\n'
            '        return toNative(args, index, exception);\n'
            '    }\n',
            RETURN_TYPE=return_type,
            TO_NATIVE_BODY=to_native_body,
            TO_NATIVE_ARG_BODY=to_native_arg_body,
            INTERFACE=self._interface.id)

        to_dart_emitter = emitter.Emitter()

        ext_attrs = self._interface.ext_attrs

        to_dart_emitter.Emit(
            '    static Dart_Handle toDart(NativeType* value)\n'
            '    {\n'
            '        if (!value)\n'
            '            return Dart_Null();\n'
            '        DartDOMData* domData = DartDOMData::current();\n'
            '        Dart_WeakPersistentHandle result =\n'
            '            DartDOMWrapper::lookupWrapper<Dart$(INTERFACE)>(domData, value);\n'
            '        if (result)\n'
            '            return Dart_HandleFromWeakPersistent(result);\n'
            '        return createWrapper(domData, value);\n'
            '    }\n'
            '    static void returnToDart(Dart_NativeArguments args,\n'
            '                             NativeType* value,\n'
            '                             bool autoDartScope = true)\n'
            '    {\n'
            '        if (value) {\n'
            '            DartDOMData* domData = static_cast<DartDOMData*>(\n'
            '                Dart_GetNativeIsolateData(args));\n'
            '            Dart_WeakPersistentHandle result =\n'
            '                DartDOMWrapper::lookupWrapper<Dart$(INTERFACE)>(domData, value);\n'
            '            if (result)\n'
            '                Dart_SetWeakHandleReturnValue(args, result);\n'
            '            else {\n'
            '                if (autoDartScope) {\n'
            '                    Dart_SetReturnValue(args, createWrapper(domData, value));\n'
            '                } else {\n'
            '                    DartApiScope apiScope;\n'
            '                    Dart_SetReturnValue(args, createWrapper(domData, value));\n'
            '               }\n'
            '            }\n'
            '        }\n'
            '    }\n',
            INTERFACE=self._interface.id)

        if ('CustomToV8' in ext_attrs or 'PureInterface' in ext_attrs or
                'CPPPureInterface' in ext_attrs or
                'SpecialWrapFor' in ext_attrs or
            ('Custom' in ext_attrs and ext_attrs['Custom'] == 'Wrap') or
            ('Custom' in ext_attrs and ext_attrs['Custom'] == 'ToV8') or
                self._interface_type_info.custom_to_dart()):
            to_dart_emitter.Emit(
                '    static Dart_Handle createWrapper(DartDOMData* domData, NativeType* value);\n'
            )
        else:
            to_dart_emitter.Emit(
                '    static Dart_Handle createWrapper(DartDOMData* domData, NativeType* value)\n'
                '    {\n'
                '        return DartDOMWrapper::createWrapper<Dart$(INTERFACE)>(domData, value, Dart$(INTERFACE)::dartClassId);\n'
                '    }\n',
                INTERFACE=self._interface.id)

        webcore_includes = self._GenerateCPPIncludes(
            self._interface_type_info.webcore_includes())

        is_node_test = lambda interface: interface.id == 'Node'
        is_active_test = lambda interface: 'ActiveDOMObject' in interface.ext_attrs
        is_event_target_test = lambda interface: 'EventTarget' in interface.ext_attrs

        def TypeCheckHelper(test):
            return 'true' if any(
                map(test, self._database.Hierarchy(
                    self._interface))) else 'false'

        to_active_emitter = emitter.Emitter()
        to_node_emitter = emitter.Emitter()
        to_event_target_emitter = emitter.Emitter()

        if (any(map(is_active_test,
                    self._database.Hierarchy(self._interface)))):
            to_active_emitter.Emit('return toNative(value);')
        else:
            to_active_emitter.Emit('return 0;')

        if (any(map(is_node_test, self._database.Hierarchy(self._interface)))):
            to_node_emitter.Emit('return toNative(value);')
        else:
            to_node_emitter.Emit('return 0;')

        if (any(
                map(is_event_target_test,
                    self._database.Hierarchy(self._interface)))):
            to_event_target_emitter.Emit('return toNative(value);')
        else:
            to_event_target_emitter.Emit('return 0;')

        v8_interface_include = ''
        # V8AbstractWorker.h does not exist so we have to hard code this case.
        if self._interface.id != 'AbstractWorker':
            # FIXME: We need this to access the WrapperTypeInfo.
            v8_interface_include = '#include "V8%s.h"' % (self._interface.id)

        self._cpp_header_emitter.Emit(
            self._template_loader.Load('cpp_header.template'),
            INTERFACE=self._interface.id,
            WEBCORE_INCLUDES=webcore_includes,
            V8_INTERFACE_INCLUDE=v8_interface_include,
            WEBCORE_CLASS_NAME=self._interface_type_info.native_type(),
            WEBCORE_CLASS_NAME_ESCAPED=self._interface_type_info.native_type().
            replace('<', '_').replace('>', '_'),
            DECLARATIONS=self._cpp_declarations_emitter.Fragments(),
            IS_NODE=TypeCheckHelper(is_node_test),
            IS_ACTIVE=TypeCheckHelper(is_active_test),
            IS_EVENT_TARGET=TypeCheckHelper(is_event_target_test),
            TO_NODE=to_node_emitter.Fragments(),
            TO_ACTIVE=to_active_emitter.Fragments(),
            TO_EVENT_TARGET=to_event_target_emitter.Fragments(),
            TO_NATIVE=to_native_emitter.Fragments(),
            TO_DART=to_dart_emitter.Fragments())

    def EmitAttribute(self, attribute, html_name, read_only):
        self._AddGetter(attribute, html_name, read_only)
        if not read_only:
            self._AddSetter(attribute, html_name)

    def _GenerateAutoSetupScope(self, idl_name, native_suffix):
        return None

    def _AddGetter(self, attr, html_name, read_only):
        # Temporary hack to force dart:scalarlist clamped array for ImageData.data.
        # TODO(antonm): solve in principled way.
        if self._interface.id == 'ImageData' and html_name == 'data':
            html_name = '_data'
        type_info = self._TypeInfo(attr.type.id)

        return_type = self.SecureOutputType(
            attr.type.id, False, False if self._dart_use_blink else True)
        dictionary_returned = False
        # Return type for dictionary is any (untyped).
        if attr.type.id == 'Dictionary':
            return_type = ''
            dictionary_returned = True

        parameters = []
        dart_declaration = '%s get %s' % (return_type, html_name)
        is_custom = _IsCustom(attr) and (_IsCustomValue(attr, None) or
                                         _IsCustomValue(attr, 'Getter'))

        # Operation uses blink?
        wrap_unwrap_list = []
        return_wrap_jso = False
        if self._dart_use_blink:
            # Unwrap the type to get the JsObject if Type is:
            #
            #    - known IDL type
            #    - type_id is None then it's probably a union type or overloaded
            #      it's a dynamic/any type
            #    - type is Object
            #
            # JsObject maybe stored in the Dart class.
            return_wrap_jso = wrap_return_type_blink(return_type, attr.type.id,
                                                     self._type_registry)
        wrap_unwrap_list.append(return_wrap_jso)  # wrap_jso the returned object
        wrap_unwrap_list.append(self._dart_use_blink)

        # This seems to have been replaced with Custom=Getter (see above), but
        # check to be sure we don't see the old syntax
        assert (not ('CustomGetter' in attr.ext_attrs))
        native_suffix = 'Getter'
        auto_scope_setup = self._GenerateAutoSetupScope(attr.id, native_suffix)
        native_entry = \
            self.DeriveNativeEntry(attr.id, 'Getter', None)
        output_conversion = self._OutputConversion(attr.type.id, attr.id)

        cpp_callback_name = self._GenerateNativeBinding(
            attr.id,
            1,
            dart_declaration,
            attr.is_static,
            return_type,
            parameters,
            native_suffix,
            is_custom,
            auto_scope_setup,
            native_entry=native_entry,
            wrap_unwrap_list=wrap_unwrap_list,
            dictionary_return=dictionary_returned,
            output_conversion=output_conversion)
        if is_custom:
            return

        if 'Reflect' in attr.ext_attrs:
            webcore_function_name = self._TypeInfo(
                attr.type.id).webcore_getter_name()
            if 'URL' in attr.ext_attrs:
                if 'NonEmpty' in attr.ext_attrs:
                    webcore_function_name = 'getNonEmptyURLAttribute'
                else:
                    webcore_function_name = 'getURLAttribute'
        elif 'ImplementedAs' in attr.ext_attrs:
            webcore_function_name = attr.ext_attrs['ImplementedAs']
        else:
            if attr.id == 'operator':
                webcore_function_name = '_operator'
            elif attr.id == 'target' and attr.type.id == 'SVGAnimatedString':
                webcore_function_name = 'svgTarget'
            elif attr.id == 'CSS':
                webcore_function_name = 'css'
            else:
                webcore_function_name = self._ToWebKitName(attr.id)

        function_expression = self._GenerateWebCoreFunctionExpression(
            webcore_function_name, attr)
        raises = ('RaisesException' in attr.ext_attrs and
                  attr.ext_attrs['RaisesException'] != 'Setter')

    def _AddSetter(self, attr, html_name):
        return_type = 'void'
        ptype = self._DartType(attr.type.id)

        type_info = self._TypeInfo(attr.type.id)

        # Is the setter value a DartClass (that has a JsObject) or the type is
        # None (it's a dynamic/any type) then unwrap_jso before passing to blink.
        parameters = ['value']

        dart_declaration = 'set %s(%s value)' % (html_name, ptype)
        is_custom = _IsCustom(attr) and (_IsCustomValue(attr, None) or
                                         _IsCustomValue(attr, 'Setter'))
        # This seems to have been replaced with Custom=Setter (see above), but
        # check to be sure we don't see the old syntax
        assert (not ('CustomSetter' in attr.ext_attrs))
        assert (not ('V8CustomSetter' in attr.ext_attrs))
        native_suffix = 'Setter'
        auto_scope_setup = self._GenerateAutoSetupScope(attr.id, native_suffix)
        native_entry = \
            self.DeriveNativeEntry(attr.id, 'Setter', None)

        # setters return no object and if blink this must be unwrapped.?
        wrap_unwrap_list = [False, self._dart_use_blink]

        cpp_callback_name = self._GenerateNativeBinding(
            attr.id,
            2,
            dart_declaration,
            attr.is_static,
            return_type,
            parameters,
            native_suffix,
            is_custom,
            auto_scope_setup,
            native_entry=native_entry,
            wrap_unwrap_list=wrap_unwrap_list)
        if is_custom:
            return

        if 'Reflect' in attr.ext_attrs:
            webcore_function_name = self._TypeInfo(
                attr.type.id).webcore_setter_name()
        else:
            if 'ImplementedAs' in attr.ext_attrs:
                attr_name = attr.ext_attrs['ImplementedAs']
            else:
                attr_name = attr.id
            webcore_function_name = re.sub(r'^(xml|css|(?=[A-Z])|\w)',
                                           lambda s: s.group(1).upper(),
                                           attr_name)
            webcore_function_name = 'set%s' % webcore_function_name

        function_expression = self._GenerateWebCoreFunctionExpression(
            webcore_function_name, attr)
        raises = ('RaisesException' in attr.ext_attrs and
                  attr.ext_attrs['RaisesException'] != 'Getter')

    def AddIndexer(self, element_type, nullable):
        """Adds all the methods required to complete implementation of List."""
        # We would like to simply inherit the implementation of everything except
        # length, [], and maybe []=.  It is possible to extend from a base
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
        elif self._HasExplicitIndexedGetter():
            self._EmitExplicitIndexedGetter(dart_element_type)
        else:
            is_custom = any((op.id == 'item' and _IsCustom(op))
                            for op in self._interface.operations)

            output_conversion = self._OutputConversion(element_type, 'item')
            conversion_name = ''
            if output_conversion:
                conversion_name = output_conversion.function_name

            # First emit a toplevel function to do the native call
            # Calls to this are emitted elsewhere,
            dart_native_name, resolver_string = \
                self.DeriveNativeEntry("item", 'Method', 1)

            # Emit the method which calls the toplevel function, along with
            # the [] operator.
            dart_qualified_name = \
                self.DeriveQualifiedBlinkName(self._interface.id,
                                              dart_native_name)

            type_info = self._TypeInfo(element_type)
            blinkNativeIndexed = """
  $TYPE operator[](int index) {
    if (index < 0 || index >= length)
      throw new RangeError.index(index, this);
    return _nativeIndexedGetter(index);
  }

  $TYPE _nativeIndexedGetter(int index) => $(CONVERSION_NAME)($(DART_NATIVE_NAME)(this, index));
"""
            blinkNativeIndexedGetter = \
                ' $(DART_NATIVE_NAME)(this, index);\n'
            self._members_emitter.Emit(
                blinkNativeIndexed,
                DART_NATIVE_NAME=dart_qualified_name,
                TYPE=self.SecureOutputType(element_type),
                INTERFACE=self._interface.id,
                CONVERSION_NAME=conversion_name)

        if self._HasNativeIndexSetter():
            self._EmitNativeIndexSetter(dart_element_type)
        else:
            self._members_emitter.Emit(
                '\n'
                '  void operator[]=(int index, $TYPE value) {\n'
                '    throw new UnsupportedError("Cannot assign element of immutable List.");\n'
                '  }\n',
                TYPE=dart_element_type)

        self.EmitListMixin(dart_element_type, nullable)

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
        return 'CustomIndexedGetter' in self._interface.ext_attrs

    def _EmitNativeIndexGetter(self, element_type):
        return_type = self.SecureOutputType(element_type, True)
        parameters = ['index']
        dart_declaration = '%s operator[](int index)' % return_type
        self._GenerateNativeBinding('numericIndexGetter', 2, dart_declaration,
                                    False, return_type, parameters, 'Callback',
                                    True, False)

    def _HasExplicitIndexedGetter(self):
        return any(op.id == 'getItem' for op in self._interface.operations)

    def _EmitExplicitIndexedGetter(self, dart_element_type):
        if any(op.id == 'getItem' for op in self._interface.operations):
            indexed_getter = 'getItem'

        self._members_emitter.Emit(
            '\n'
            '  $TYPE operator[](int index) {\n'
            '    if (index < 0 || index >= length)\n'
            '      throw new RangeError.index(index, this);\n'
            '    return $INDEXED_GETTER(index);\n'
            '  }\n',
            TYPE=dart_element_type,
            INDEXED_GETTER=indexed_getter)

    def _HasNativeIndexSetter(self):
        return 'CustomIndexedSetter' in self._interface.ext_attrs

    def _EmitNativeIndexSetter(self, element_type):
        return_type = 'void'
        formals = ', '.join(['int index', '%s value' % element_type])
        parameters = ['index', 'value']
        dart_declaration = 'void operator[]=(%s)' % formals
        self._GenerateNativeBinding('numericIndexSetter', 3, dart_declaration,
                                    False, return_type, parameters, 'Callback',
                                    True, False)

    def _ChangePrivateOpMapArgToAny(self, operations):
        # TODO(terry): Hack to map any operations marked as private to not
        #              handle converting Map to native (JsObject) the public
        #              members that call the private method will have done
        #              conversions.
        for operation in operations:
            for arg in operation.arguments:
                type = arg.type
                if type.id == 'Dictionary':
                    type.id = 'any'

    def EmitOperation(self, info, html_name, dart_js_interop=False):
        """
    Arguments:
      info: An OperationInfo object.
    """
        if self._renamer.isPrivate(self._interface, info.operations[0].id):
            # Any private operations with Maps parameters changed to any type.
            # The public method that delegates to this private operation has already
            # converted from Map to native (JsObject) e.g., Element.animate.
            self._ChangePrivateOpMapArgToAny(info.operations)

        return_type = self.SecureOutputType(info.type_name, False,
                                            False if dart_js_interop else True)

        formals = info.ParametersAsDeclaration(self._DartType)

        parameters = info.ParametersAsListOfVariables(
            None, self._type_registry if self._dart_use_blink else None,
            dart_js_interop, self)

        operation = info.operations[0]

        output_conversion = self._OutputConversion(operation.type.id,
                                                   operation.id)

        dictionary_returned = False
        # Return type for dictionary is any (untyped).
        if operation.type.id == 'Dictionary':
            return_type = ''
            dictionary_returned = True

        dart_declaration = '%s%s %s(%s)' % ('static ' if info.IsStatic() else
                                            '', return_type, html_name, formals)

        is_custom = _IsCustom(operation)
        has_optional_arguments = any(
            IsOptional(argument) for argument in operation.arguments)
        needs_dispatcher = not is_custom and (len(info.operations) > 1 or
                                              has_optional_arguments)

        # Operation uses blink?
        wrap_unwrap_list = []
        return_wrap_jso = False
        # return type wrapped?
        if self._dart_use_blink:
            # Wrap the type to store the JsObject if Type is:
            #
            #      it's a dynamic/any type
            #    - type is Object
            #
            # JsObject maybe stored in the Dart class.
            return_wrap_jso = wrap_return_type_blink(
                return_type, info.type_name, self._type_registry)
            return_type_info = self._type_registry.TypeInfo(info.type_name)
        # wrap_jso the returned object
        wrap_unwrap_list.append(return_wrap_jso)
        wrap_unwrap_list.append(self._dart_use_blink)

        if info.callback_args:
            self._AddFutureifiedOperation(info, html_name)
        elif not needs_dispatcher:
            # Bind directly to native implementation
            argument_count = (0 if info.IsStatic() else 1) + len(
                info.param_infos)
            native_suffix = 'Callback'
            auto_scope_setup = self._GenerateAutoSetupScope(
                info.name, native_suffix)
            native_entry = \
                self.DeriveNativeEntry(operation.id, 'Method', len(info.param_infos))
            cpp_callback_name = self._GenerateNativeBinding(
                info.name,
                argument_count,
                dart_declaration,
                info.IsStatic(),
                return_type,
                parameters,
                native_suffix,
                is_custom,
                auto_scope_setup,
                native_entry=native_entry,
                wrap_unwrap_list=wrap_unwrap_list,
                dictionary_return=dictionary_returned,
                output_conversion=output_conversion)
            if not is_custom:
                self._GenerateOperationNativeCallback(
                    operation, operation.arguments, cpp_callback_name,
                    auto_scope_setup)
        else:
            self._GenerateDispatcher(info, info.operations, dart_declaration,
                                     html_name)

    def _GenerateDispatcher(self, info, operations, dart_declaration,
                            html_name):

        def GenerateCall(stmts_emitter, call_emitter, version, operation,
                         argument_count):
            native_suffix = 'Callback'
            actuals = info.ParametersAsListOfVariables(
                argument_count,
                self._type_registry if self._dart_use_blink else None,
                self._dart_js_interop, self)
            actuals_s = ", ".join(actuals)
            formals = actuals
            return_type = self.SecureOutputType(operation.type.id)

            return_wrap_jso = False
            if self._dart_use_blink:
                return_wrap_jso = wrap_return_type_blink(
                    return_type, info.type_name, self._type_registry)

            native_suffix = 'Callback'
            is_custom = _IsCustom(operation)
            base_name = '_%s_%s' % (operation.id, version)
            static = True
            if not operation.is_static:
                actuals = ['this'] + actuals
                formals = ['mthis'] + formals
            actuals_s = ", ".join(actuals)
            formals_s = ", ".join(formals)
            dart_declaration = '%s(%s)' % (base_name, formals_s)
            native_entry = \
                self.DeriveNativeEntry(operation.id, 'Method', argument_count)
            overload_base_name = native_entry[0]
            overload_name = \
                self.DeriveQualifiedBlinkName(self._interface.id,
                                              overload_base_name)
            call_emitter.Emit(
                '$NAME($ARGS)', NAME=overload_name, ARGS=actuals_s)
            auto_scope_setup = \
              self._GenerateAutoSetupScope(base_name, native_suffix)
            cpp_callback_name = self._GenerateNativeBinding(
                base_name, (0 if static else 1) + argument_count,
                dart_declaration,
                static,
                return_type,
                formals,
                native_suffix,
                is_custom,
                auto_scope_setup,
                emit_metadata=False,
                emit_to_native=True,
                native_entry=native_entry)
            if not is_custom:
                self._GenerateOperationNativeCallback(
                    operation, operation.arguments[:argument_count],
                    cpp_callback_name, auto_scope_setup)

        self._GenerateDispatcherBody(info, operations, dart_declaration,
                                     GenerateCall, IsOptional)

    def SecondaryContext(self, interface):
        pass

    def _GenerateOperationNativeCallback(self,
                                         operation,
                                         arguments,
                                         cpp_callback_name,
                                         auto_scope_setup=True):
        webcore_function_name = operation.ext_attrs.get('ImplementedAs',
                                                        operation.id)

        function_expression = self._GenerateWebCoreFunctionExpression(
            webcore_function_name, operation, cpp_callback_name)

    def _GenerateNativeBinding(self,
                               idl_name,
                               argument_count,
                               dart_declaration,
                               static,
                               return_type,
                               parameters,
                               native_suffix,
                               is_custom,
                               auto_scope_setup=True,
                               emit_metadata=True,
                               emit_to_native=False,
                               native_entry=None,
                               wrap_unwrap_list=[],
                               dictionary_return=False,
                               output_conversion=None):
        metadata = []
        if emit_metadata:
            metadata = self._metadata.GetFormattedMetadata(
                self._renamer.GetLibraryName(self._interface), self._interface,
                idl_name, '  ')

        if (native_entry):
            dart_native_name, native_binding = native_entry
        else:
            dart_native_name = \
                self.DeriveNativeName(idl_name, native_suffix)
            native_binding_id = self._interface.id
            native_binding_id = TypeIdToBlinkName(native_binding_id,
                                                  self._database)
            native_binding = \
                '%s_%s_%s' % (native_binding_id, idl_name, native_suffix)

        if not static:
            formals = ", ".join(['mthis'] + parameters)
            actuals = ", ".join(['this'] + parameters)
        else:
            formals = ", ".join(parameters)
            actuals = ", ".join(parameters)

        if not emit_to_native:
            caller_emitter = self._members_emitter
            full_dart_name = \
                self.DeriveQualifiedBlinkName(self._interface.id,
                                              dart_native_name)
            if IsPureInterface(self._interface.id, self._database):
                caller_emitter.Emit('\n'
                                    '  $METADATA$DART_DECLARATION;\n',
                                    METADATA=metadata,
                                    DART_DECLARATION=dart_declaration)
            else:
                emit_template = '''
  $METADATA$DART_DECLARATION => $DART_NAME($ACTUALS);
  '''
                if output_conversion and not dictionary_return:
                    conversion_template = '''
  $METADATA$DART_DECLARATION => %s($DART_NAME($ACTUALS));
  '''
                    emit_template = conversion_template % output_conversion.function_name

                elif wrap_unwrap_list and wrap_unwrap_list[0]:
                    if return_type == 'Rectangle':
                        jso_util_method = 'make_dart_rectangle'
                    elif wrap_unwrap_list[0]:
                        jso_util_method = ''

                    if dictionary_return:
                        emit_jso_template = '''
  $METADATA$DART_DECLARATION => convertNativeDictionaryToDartDictionary(%s($DART_NAME($ACTUALS)));
  '''
                    else:
                        emit_jso_template = '''
  $METADATA$DART_DECLARATION => %s($DART_NAME($ACTUALS));
  '''
                    emit_template = emit_jso_template % jso_util_method

                if caller_emitter:
                    caller_emitter.Emit(
                        emit_template,
                        METADATA=metadata,
                        DART_DECLARATION=dart_declaration,
                        DART_NAME=full_dart_name,
                        ACTUALS=actuals)
        cpp_callback_name = '%s%s' % (idl_name, native_suffix)

        self._cpp_resolver_emitter.Emit(
            '    if (argumentCount == $ARGC && name == "$NATIVE_BINDING") {\n'
            '        *autoSetupScope = $AUTO_SCOPE_SETUP;\n'
            '        return Dart$(INTERFACE_NAME)Internal::$CPP_CALLBACK_NAME;\n'
            '    }\n',
            ARGC=argument_count,
            NATIVE_BINDING=native_binding,
            INTERFACE_NAME=self._interface.id,
            AUTO_SCOPE_SETUP='true' if auto_scope_setup else 'false',
            CPP_CALLBACK_NAME=cpp_callback_name)

        if is_custom:
            self._cpp_declarations_emitter.Emit(
                '\n'
                'void $CPP_CALLBACK_NAME(Dart_NativeArguments);\n',
                CPP_CALLBACK_NAME=cpp_callback_name)

        return cpp_callback_name

    def _GenerateWebCoreReflectionAttributeName(self, attr):
        namespace = 'HTMLNames'
        svg_exceptions = [
            'class', 'id', 'onabort', 'onclick', 'onerror', 'onload',
            'onmousedown', 'onmousemove', 'onmouseout', 'onmouseover',
            'onmouseup', 'onresize', 'onscroll', 'onunload'
        ]
        if self._interface.id.startswith(
                'SVG') and not attr.id in svg_exceptions:
            namespace = 'SVGNames'
        self._cpp_impl_includes.add('"%s.h"' % namespace)

        attribute_name = attr.ext_attrs['Reflect'] or attr.id.lower()
        return 'WebCore::%s::%sAttr' % (namespace, attribute_name)

    def _IsStatic(self, attribute_name):
        return False

    def _GenerateWebCoreFunctionExpression(self,
                                           function_name,
                                           idl_node,
                                           cpp_callback_name=None):
        return None

    def _IsArgumentOptionalInWebCore(self, operation, argument):
        if not IsOptional(argument):
            return False
        if 'Callback' in argument.ext_attrs:
            return False
        if operation.id in ['addEventListener', 'removeEventListener'
                           ] and argument.id == 'useCapture':
            return False
        if 'DartForceOptional' in argument.ext_attrs:
            return False
        if argument.type.id == 'Dictionary':
            return False
        return True

    def _GenerateCPPIncludes(self, includes):
        return None

    def _ToWebKitName(self, name):
        name = name[0].lower() + name[1:]
        name = re.sub(r'^(hTML|uRL|jS|xML|xSLT)', lambda s: s.group(1).lower(),
                      name)
        return re.sub(r'^(create|exclusive)',
                      lambda s: 'is' + s.group(1).capitalize(), name)


class CPPLibraryEmitter():

    def __init__(self, emitters, cpp_sources_dir):
        self._emitters = emitters
        self._cpp_sources_dir = cpp_sources_dir
        self._library_headers = dict((lib, []) for lib in HTML_LIBRARY_NAMES)
        self._sources_list = []

    def CreateHeaderEmitter(self,
                            interface_name,
                            library_name,
                            is_callback=False):
        path = os.path.join(self._cpp_sources_dir, 'Dart%s.h' % interface_name)
        if not is_callback:
            self._library_headers[library_name].append(path)
        return self._emitters.FileEmitter(path)

    def CreateSourceEmitter(self, interface_name):
        path = os.path.join(self._cpp_sources_dir,
                            'Dart%s.cpp' % interface_name)
        self._sources_list.append(path)
        return self._emitters.FileEmitter(path)

    def EmitDerivedSources(self, template, output_dir):
        partitions = 20  # FIXME: this should be configurable.
        sources_count = len(self._sources_list)
        for i in range(0, partitions):
            file_path = os.path.join(output_dir,
                                     'DartDerivedSources%02i.cpp' % (i + 1))
            includes_emitter = self._emitters.FileEmitter(file_path).Emit(
                template)
            for source_file in self._sources_list[i::partitions]:
                path = os.path.relpath(source_file, output_dir)
                includes_emitter.Emit('#include "$PATH"\n', PATH=path)

    def EmitResolver(self, template, output_dir):
        for library_name in self._library_headers.keys():
            file_path = os.path.join(output_dir,
                                     '%s_DartResolver.cpp' % library_name)
            includes_emitter, body_emitter = self._emitters.FileEmitter(
                file_path).Emit(
                    template, LIBRARY_NAME=library_name)

            headers = self._library_headers[library_name]
            for header_file in headers:
                path = os.path.relpath(header_file, output_dir)
                includes_emitter.Emit('#include "$PATH"\n', PATH=path)
                body_emitter.Emit(
                    '    if (Dart_NativeFunction func = $CLASS_NAME::resolver(name, argumentCount, autoSetupScope))\n'
                    '        return func;\n',
                    CLASS_NAME=os.path.splitext(os.path.basename(path))[0])

    def EmitClassIdTable(self, database, output_dir, type_registry, renamer):

        def HasConverters(interface):
            is_node_test = lambda interface: interface.id == 'Node'
            is_active_test = lambda interface: 'ActiveDOMObject' in interface.ext_attrs
            is_event_target_test = lambda interface: 'EventTarget' in interface.ext_attrs

            return (
                any(map(is_node_test, database.Hierarchy(interface))) or
                any(map(is_active_test, database.Hierarchy(interface))) or
                any(map(is_event_target_test, database.Hierarchy(interface))))

        path = os.path.join(output_dir, 'DartWebkitClassIds.h')
        e = self._emitters.FileEmitter(path)
        e.Emit(
            '// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file\n'
        )
        e.Emit(
            '// for details. All rights reserved. Use of this source code is governed by a\n'
        )
        e.Emit('// BSD-style license that can be found in the LICENSE file.\n')
        e.Emit('// WARNING: Do not edit - generated code.\n')
        e.Emit('// See dart/tools/dom/scripts/systemnative.py\n')
        e.Emit('\n')
        e.Emit('#ifndef DartWebkitClassIds_h\n')
        e.Emit('#define DartWebkitClassIds_h\n')
        e.Emit('\n')
        e.Emit('namespace WebCore {\n')
        e.Emit('\n')
        e.Emit('enum {\n')
        e.Emit('    _InvalidClassId = 0,\n')
        e.Emit('    _HistoryCrossFrameClassId,\n')
        e.Emit('    _LocationCrossFrameClassId,\n')
        e.Emit('    _DOMWindowCrossFrameClassId,\n')
        e.Emit('    _DateTimeClassId,\n')
        e.Emit('    _JsObjectClassId,\n')
        e.Emit('    _JsFunctionClassId,\n')
        e.Emit('    _JsArrayClassId,\n')
        e.Emit(
            '    // New types that are not auto-generated should be added here.\n'
        )
        e.Emit('\n')
        for interface in database.GetInterfaces():
            e.Emit('    %sClassId,\n' % interface.id)
        e.Emit('    NumWebkitClassIds\n')
        e.Emit('};\n')
        e.Emit(
            'class ActiveDOMObject;\n'
            'class EventTarget;\n'
            'class Node;\n'
            'typedef ActiveDOMObject* (*ToActiveDOMObject)(void* value);\n'
            'typedef EventTarget* (*ToEventTarget)(void* value);\n'
            'typedef Node* (*ToNode)(void* value);\n'
            'typedef struct {\n'
            '    const char* class_name;\n'
            '    int library_id;\n'
            '    int base_class_id;\n'
            '    ToActiveDOMObject toActiveDOMObject;\n'
            '    ToEventTarget toEventTarget;\n'
            '    ToNode toNode;\n'
            '} DartWrapperTypeInfo;\n'
            'typedef DartWrapperTypeInfo _DartWebkitClassInfo[NumWebkitClassIds];\n'
            '\n'
            'extern _DartWebkitClassInfo DartWebkitClassInfo;\n'
            '\n'
            '} // namespace WebCore\n'
            '#endif // DartWebkitClassIds_h\n')

        path = os.path.join(output_dir, 'DartWebkitClassIds.cpp')
        e = self._emitters.FileEmitter(path)
        e.Emit(
            '// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file\n'
        )
        e.Emit(
            '// for details. All rights reserved. Use of this source code is governed by a\n'
        )
        e.Emit('// BSD-style license that can be found in the LICENSE file.\n')
        e.Emit('// WARNING: Do not edit - generated code.\n')
        e.Emit('// See dart/tools/dom/scripts/systemnative.py\n')
        e.Emit('\n')
        e.Emit('#include "config.h"\n')
        e.Emit('#include "DartWebkitClassIds.h"\n')
        e.Emit('\n')
        e.Emit('#include "bindings/dart/DartLibraryIds.h"\n')
        for interface in database.GetInterfaces():
            if HasConverters(interface):
                e.Emit('#include "Dart%s.h"\n' % interface.id)
        e.Emit('\n')

        e.Emit('namespace WebCore {\n')

        e.Emit('\n')

        e.Emit(
            'ActiveDOMObject* toNullActiveDOMObject(void* value) { return 0; }\n'
        )
        e.Emit('EventTarget* toNullEventTarget(void* value) { return 0; }\n')
        e.Emit('Node* toNullNode(void* value) { return 0; }\n')

        e.Emit("_DartWebkitClassInfo DartWebkitClassInfo = {\n")

        e.Emit('    {\n'
               '        "_InvalidClassId", -1, -1,\n'
               '        toNullActiveDOMObject, toNullEventTarget, toNullNode\n'
               '    },\n')
        e.Emit('    {\n'
               '        "_HistoryCrossFrame", DartHtmlLibraryId, -1,\n'
               '        toNullActiveDOMObject, toNullEventTarget, toNullNode\n'
               '    },\n')
        e.Emit('    {\n'
               '        "_LocationCrossFrame", DartHtmlLibraryId, -1,\n'
               '        toNullActiveDOMObject, toNullEventTarget, toNullNode\n'
               '    },\n')
        e.Emit('    {\n'
               '        "_DOMWindowCrossFrame", DartHtmlLibraryId, -1,\n'
               '        toNullActiveDOMObject, toNullEventTarget, toNullNode\n'
               '    },\n')
        e.Emit('    {\n'
               '        "DateTime", DartCoreLibraryId, -1,\n'
               '        toNullActiveDOMObject, toNullEventTarget, toNullNode\n'
               '    },\n')
        e.Emit('    {\n'
               '        "JsObject", DartJsLibraryId, -1,\n'
               '        toNullActiveDOMObject, toNullEventTarget, toNullNode\n'
               '    },\n')
        e.Emit('    {\n'
               '        "JsFunction", DartJsLibraryId, _JsObjectClassId,\n'
               '        toNullActiveDOMObject, toNullEventTarget, toNullNode\n'
               '    },\n')
        e.Emit('    {\n'
               '        "JsArray", DartJsLibraryId, _JsObjectClassId,\n'
               '        toNullActiveDOMObject, toNullEventTarget, toNullNode\n'
               '    },\n')
        e.Emit(
            '    // New types that are not auto-generated should be added here.\n'
        )
        for interface in database.GetInterfaces():
            name = interface.id
            type_info = type_registry.TypeInfo(name)
            type_info.native_type().replace('<', '_').replace('>', '_')
            e.Emit('    {\n')
            e.Emit('        "%s", ' % type_info.implementation_name())
            e.Emit('Dart%sLibraryId, ' % renamer.GetLibraryId(interface))
            if interface.parents:
                supertype = interface.parents[0].type.id
                e.Emit('%sClassId,\n' % supertype)
            else:
                e.Emit(' -1,\n')
            if HasConverters(interface):
                e.Emit(
                    '        Dart%s::toActiveDOMObject, Dart%s::toEventTarget,'
                    ' Dart%s::toNode\n' % (name, name, name))
            else:
                e.Emit(
                    '        toNullActiveDOMObject, toNullEventTarget, toNullNode\n'
                )
            e.Emit('    },\n')

        e.Emit("};\n")
        e.Emit('\n')
        e.Emit('} // namespace WebCore\n')


def _IsOptionalStringArgumentInInitEventMethod(interface, operation, argument):
    return (interface.id.endswith('Event') and
            operation.id.startswith('init') and
            argument.default_value == 'Undefined' and
            argument.type.id == 'DOMString')


def _IsCustom(op_or_attr):
    assert (isinstance(op_or_attr, IDLMember))
    return 'Custom' in op_or_attr.ext_attrs or 'DartCustom' in op_or_attr.ext_attrs


def _IsCustomValue(op_or_attr, value):
    if _IsCustom(op_or_attr):
        return op_or_attr.ext_attrs.get('Custom') == value \
               or op_or_attr.ext_attrs.get('DartCustom') == value
    return False
