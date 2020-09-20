#!/usr/bin/python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.
"""This module provides shared functionality for the system to generate
dart:html APIs from the IDL database."""

import emitter
from generator import AnalyzeOperation, ConstantOutputOrder, \
    DartDomNameOfAttribute, FindMatchingAttribute, IsPureInterface, \
    TypeOrNothing, ConvertToFuture, GetCallbackInfo
from copy import deepcopy
from htmlrenamer import convert_to_future_members, custom_html_constructors, \
    GetDDC_Extension, keep_overloaded_members, overloaded_and_renamed,\
    private_html_members, renamed_html_members, renamed_overloads, \
    removed_html_members
from generator import TypeOrVar
import logging
from mdnreader import MDNReader
import monitored
import sys

_logger = logging.getLogger('htmldartgenerator')

# Types that are accessible cross-frame in a limited fashion.
# In these cases, the base type (e.g., WindowBase) provides restricted access
# while the subtype (e.g., Window) provides full access to the
# corresponding objects if there are from the same frame.
_secure_base_types = {
    'Window': 'WindowBase',
    'Location': 'LocationBase',
    'History': 'HistoryBase',
}

_custom_factories = [
    'Notification',
    'EventSource',
]


class HtmlDartGenerator(object):

    def __init__(self, interface, options, dart_use_blink, logger):
        self._dart_use_blink = dart_use_blink
        self._database = options.database
        self._interface = interface
        self._type_registry = options.type_registry
        self._interface_type_info = self._type_registry.TypeInfo(
            self._interface.id)
        self._renamer = options.renamer
        self._metadata = options.metadata
        self._library_name = self._renamer.GetLibraryName(self._interface)
        self._mdn_reader = MDNReader()
        _logger.setLevel(logger.level)

    def EmitSupportCheck(self):
        if self.HasSupportCheck():
            check = self.GetSupportCheck()
            if type(check) != tuple:
                signature = 'get supported'
            else:
                signature = check[0]
                check = check[1]
            self._members_emitter.Emit(
                '\n'
                '  /// Checks if this type is supported on the current platform.\n'
                '  static bool $SIGNATURE => $SUPPORT_CHECK;\n',
                SIGNATURE=signature,
                SUPPORT_CHECK=check)

    def EmitEventGetter(self, events_class_name):
        self._members_emitter.Emit(
            "EventTarget.removeEventListener, EventTarget.dispatchEvent')"
            "\n  @deprecated"
            "\n  $TYPE get on =>\n    new $TYPE(this);\n",
            TYPE=events_class_name)

    def AddMembers(self, interface, declare_only=False, dart_js_interop=False):
        if self._interface.id == 'WebGLRenderingContextBase' or self._interface.id == 'WebGL2RenderingContextBase' or \
            self._interface.id == 'WebGLDrawBuffers':
            # Constants in classes WebGLRenderingContextBase, WebGL2RenderingContext, WebGLDrawBuffers are consolidated into
            # one synthesized class (WebGL).
            self._gl_constants.extend(interface.constants)
        else:
            for const in sorted(interface.constants, ConstantOutputOrder):
                self.AddConstant(const)

        for attr in sorted(interface.attributes, ConstantOutputOrder):
            if attr.type.id != 'EventHandler' and attr.type.id != 'EventListener':
                self.AddAttribute(attr, declare_only)

        # The implementation should define an indexer if the interface directly
        # extends List.
        element_type = None
        requires_indexer = False
        if self._interface_type_info.list_item_type():
            self.AddIndexer(self._interface_type_info.list_item_type(),
                            self._interface_type_info.list_item_type_nullable())
        else:
            for parent in self._database.Hierarchy(self._interface):
                if parent == self._interface:
                    continue
                parent_type_info = self._type_registry.TypeInfo(parent.id)
                if parent_type_info.list_item_type():
                    self.AmendIndexer(parent_type_info.list_item_type())
                    break

        # Group overloaded operations by name.
        self._AddRenamedOverloads(interface)
        operationsByName = self._OperationsByName(interface)
        if self.OmitOperationOverrides():
            self._RemoveShadowingOperationsWithSameSignature(
                operationsByName, interface)

        # Generate operations.
        for id in sorted(operationsByName.keys()):
            operations = operationsByName[id]
            info = AnalyzeOperation(interface, operations)
            self.AddOperation(info, declare_only, dart_js_interop)
            if ('%s.%s' % (interface.id,
                           info.declared_name) in convert_to_future_members):
                self.AddOperation(ConvertToFuture(info), declare_only)

    def AddSecondaryMembers(self, interface):
        secondary_parents = self._database.TransitiveSecondaryParents(
            interface, not self._dart_use_blink)
        remove_duplicate_parents = list(set(secondary_parents))
        if len(secondary_parents) != len(remove_duplicate_parents):
            secondary_parents = remove_duplicate_parents
            parent_list = ", ".join(
                ["  %s" % (parent.id) for parent in secondary_parents])
            _logger.warn('Interface %s has duplicate parent interfaces %s - ' \
                         'ignoring duplicates. Please file a bug with the dart:html team.' % (interface.id, parent_list))

        for parent_interface in sorted(secondary_parents):
            if isinstance(parent_interface, str):
                continue

            for attr in sorted(parent_interface.attributes,
                               ConstantOutputOrder):
                if not FindMatchingAttribute(interface, attr):
                    if attr.type.id != 'EventHandler':
                        self.SecondaryContext(parent_interface)
                        self.AddAttribute(attr)

            # Group overloaded operations by name.
            operationsByName = self._OperationsByName(parent_interface)

            if self.OmitOperationOverrides():
                self._RemoveShadowingOperationsWithSameSignature(
                    operationsByName, interface)

            # Generate operations.
            for id in sorted(operationsByName.keys()):
                if not any(op.id == id for op in interface.operations):
                    operations = operationsByName[id]
                    info = AnalyzeOperation(interface, operations)
                    self.SecondaryContext(parent_interface)
                    self.AddOperation(info)

    def _RemoveShadowingOperationsWithSameSignature(self, operationsByName,
                                                    interface):
        if not interface.parents:
            return

        parent_name = interface.parents[0].type.id
        parent = self._database.GetInterface(parent_name)
        if parent == self._interface or parent == interface:
            return

        # Never remove operations that are added as a result of an implements they
        # are pure interfaces (mixins to this interface).
        if (IsPureInterface(parent_name, self._database)):
            return

        for operation in parent.operations:
            if operation.id in operationsByName:
                operations = operationsByName[operation.id]
                for existing_operation in operations:
                    if existing_operation.SameSignatureAs(operation):
                        del operationsByName[operation.id]

    def _AddRenamedOverloads(self, interface):
        """The IDL has a number of functions with the same name but that accept
    different types. This is fine for JavaScript, but results in vague type
    signatures for Dart. We rename some of these (by adding a new identical
    operation with a different DartName), but leave the original version as
    well in some cases."""
        potential_added_operations = set()
        operations_by_name = self._OperationsByName(interface)
        already_renamed = [
            operation.ext_attrs['DartName']
            if 'DartName' in operation.ext_attrs else ''
            for operation in interface.operations
        ]

        added_operations = []
        for operation in interface.operations:
            full_operation_str = self._GetStringRepresentation(
                interface, operation)
            if (full_operation_str in renamed_overloads and
                    renamed_overloads[full_operation_str] not in already_renamed
               ):
                if '%s.%s' % (interface.id,
                              operation.id) in overloaded_and_renamed:
                    cloned_operation = deepcopy(operation)
                    cloned_operation.ext_attrs['DartName'] = renamed_overloads[
                        full_operation_str]
                    added_operations.append(cloned_operation)
                else:
                    dart_name = renamed_overloads[full_operation_str]
                    if not dart_name:
                        continue

                    operation.ext_attrs['DartName'] = dart_name
                    potential_added_operations.add(operation.id)
            self._EnsureNoMultipleTypeSignatures(interface, operation,
                                                 operations_by_name)
        interface.operations += added_operations
        self._AddDesiredOverloadedOperations(potential_added_operations,
                                             interface, operations_by_name)

    def _AddDesiredOverloadedOperations(self, potential_added_operations,
                                        interface, original_operations_by_name):
        """For some cases we desire to keep the overloaded version in dart, for
    simplicity of API, and explain the parameters accepted in documentation."""
        updated_operations_by_name = self._OperationsByName(interface)
        for operation_id in potential_added_operations:
            if (operation_id not in updated_operations_by_name and '%s.%s' %
                (interface.id, operation_id) in keep_overloaded_members):
                for operation in original_operations_by_name[operation_id]:
                    cloned_operation = deepcopy(operation)
                    cloned_operation.ext_attrs['DartName'] = operation_id
                    interface.operations.append(cloned_operation)

    def _EnsureNoMultipleTypeSignatures(self, interface, operation,
                                        operations_by_name):
        """Make sure that there is now at most one operation with a particular
    operation.id. If not, stop library generation, and throw an error, requiring
    programmer input about the best name change before proceeding."""
        operation_str = '%s.%s' % (interface.id, operation.id)

        if (operation.id in operations_by_name and
                len(operations_by_name[operation.id]) > 1 and len(
                    filter(lambda overload: overload.startswith(operation_str),
                           renamed_overloads.keys())) == 0 and
                operation_str not in keep_overloaded_members and
                operation_str not in overloaded_and_renamed and
                operation_str not in renamed_html_members and
                operation_str not in private_html_members and
                operation_str not in removed_html_members and
                operation.id != '__getter__' and
                operation.id != '__setter__' and operation.id != '__delete__'):
            _logger.warn(
                'Multiple type signatures for %s.%s. Please file a bug with'
                ' the dart:html team to determine if one of these functions should be'
                ' renamed.' % (interface.id, operation.id))

    def _GetStringRepresentation(self, interface, operation):
        """Given an IDLOperation, return a object-independent representation of the
    operations's signature."""
        return '%s.%s(%s)' % (interface.id, operation.id, ', '.join(
            ['%s %s' % (arg.type.id, arg.id) for arg in operation.arguments]))

    def _OperationsByName(self, interface):
        operationsByName = {}
        for operation in interface.operations:
            name = operation.ext_attrs.get('DartName', operation.id)
            operationsByName.setdefault(name, []).append(operation)
        return operationsByName

    def OmitOperationOverrides(self):
        return False

    def AddConstant(self, constant):
        const_name = self._renamer.RenameMember(
            self._interface.id,
            constant,
            constant.id,
            'get:',
            dartify_name=False)
        if not const_name:
            return

        annotations = self._metadata.GetFormattedMetadata(
            self._library_name, self._interface, constant.id, '  ')

        type = TypeOrNothing(self._DartType(constant.type.id), constant.type.id)
        self._members_emitter.Emit(
            '\n  $(ANNOTATIONS)static const $TYPE$NAME = $VALUE;\n',
            ANNOTATIONS=annotations,
            NAME=const_name,
            TYPE=type,
            VALUE=constant.value)

    def AddAttribute(self, attribute, declare_only=False):
        """ Adds an attribute to the generated class.
    Arguments:
      attribute - The attribute which is to be added.
      declare_only- True if the attribute should be declared as an abstract
        member and not include invocation code.
    """
        dom_name = DartDomNameOfAttribute(attribute)
        attr_name = self._renamer.RenameMember(self._interface.id, attribute,
                                               dom_name, 'get:')
        if not attr_name:
            return

        html_setter_name = self._renamer.RenameMember(
            self._interface.id, attribute, dom_name, 'set:')
        read_only = (attribute.is_read_only or
                     'Replaceable' in attribute.ext_attrs or
                     not html_setter_name)

        # We don't yet handle inconsistent renames of the getter and setter yet.
        assert (not html_setter_name or attr_name == html_setter_name)

        # any is assumed to be nullable
        if attribute.type.id == 'any':
            attribute.type.nullable = True

        if declare_only:
            self.DeclareAttribute(attribute, attr_name, read_only)
        else:
            self.EmitAttribute(attribute, attr_name, read_only)

    def AddOperation(self, info, declare_only=False, dart_js_interop=False):
        # TODO(terry): Hack window has 2 overloaded getter one returns Window and
        #              and other object (we'll always return Window)?
        if self._interface.id == "Window" and info.name == '__getter__':
            info.operations[1].type = info.operations[0].type
        """ Adds an operation to the generated class.
    Arguments:
      info - The operation info of the operation to be added.
      declare_only- True if the operation should be declared as an abstract
        member and not include invocation code.
    """
        # FIXME: When we pass in operations[0] below, we're assuming all
        # overloaded operations have the same security attributes.  This
        # is currently true, but we should consider filtering earlier or
        # merging the relevant data into info itself.
        method_name = self._renamer.RenameMember(
            self._interface.id, info.operations[0], info.name, 'call:')
        if not method_name:
            if info.name == 'item':
                # FIXME: item should be renamed to operator[], not removed.
                self.EmitOperation(info, '_item')
            return

        if declare_only:
            self.DeclareOperation(info,
                                  self.SecureOutputType(info.type_name,
                                      nullable=info.type_nullable),
                                  method_name)
        else:
            self.EmitOperation(info, method_name, dart_js_interop)

    def _GenerateOverloadDispatcher(
            self,
            info,
            signatures,
            is_void,
            declaration,
            generate_call,
            is_optional,
            emitter,
            can_omit_type_check=lambda type, pos: False):

        parameter_names = [p.name for p in info.param_infos]
        number_of_required_in_dart = info.NumberOfRequiredInDart()

        body_emitter = emitter.Emit('\n'
                                    '  $DECLARATION {\n'
                                    '$!BODY'
                                    '  }\n',
                                    DECLARATION=declaration)

        version = [0]

        def GenerateCall(signature_index, argument_count, checks):
            if checks:
                (stmts_emitter, call_emitter) = body_emitter.Emit(
                    '    if ($CHECKS) {\n$!STMTS$!CALL    }\n',
                    INDENT='      ',
                    CHECKS=' && '.join(checks))
            else:
                (stmts_emitter, call_emitter) = body_emitter.Emit(
                    '$!STMTS$!CALL', INDENT='    ')

            if is_void:
                call_emitter = call_emitter.Emit(
                    '$(INDENT)$!CALL;\n$(INDENT)return;\n')
            else:
                call_emitter = call_emitter.Emit('$(INDENT)return $!CALL;\n')

            version[0] += 1
            generate_call(stmts_emitter, call_emitter, version[0],
                          signature_index, argument_count)

        def IsTypeChecking(interface_argument):
            return 'LegacyInterfaceTypeChecking' in interface_argument.ext_attrs or \
            self._database.HasInterface(interface_argument.id)

        def GenerateChecksAndCall(signature_index, argument_count):
            checks = []
            typechecked_interface = IsTypeChecking(self._interface)

            for i in reversed(range(0, argument_count)):
                argument = signatures[signature_index][i]
                parameter_name = parameter_names[i]

                test_type = self._NarrowToImplementationType(argument.type.id)

                if test_type in ['dynamic', 'Object']:
                    checks.append('%s != null' % parameter_name)
                elif not can_omit_type_check(test_type, i):
                    typechecked = typechecked_interface or IsTypeChecking(
                        argument)
                    converts_null = \
                        ('TreatNullAs' in argument.ext_attrs) or \
                        (argument.default_value is not None) or \
                        (argument.default_value_is_null)
                    if argument.type.nullable or converts_null or not typechecked:
                        checks.append(
                            '(%s is %s || %s == null)' %
                            (parameter_name, test_type, parameter_name))
                    else:
                        checks.append(
                            '(%s is %s)' % (parameter_name, test_type))
                elif i >= number_of_required_in_dart and not argument.type.nullable:
                    checks.append('%s != null' % parameter_name)

            # There can be multiple presence checks.  We need them all since a later
            # optional argument could have been passed by name, leaving 'holes'.
            checks.extend([
                '%s == null' % name for name in parameter_names[argument_count:]
            ])

            GenerateCall(signature_index, argument_count, checks)

        # TODO: Optimize the dispatch to avoid repeated checks.
        if len(signatures) > 1:
            index_swaps = {}
            for signature_index, signature in enumerate(signatures):
                for argument_position, argument in enumerate(signature):
                    if argument.type.id != 'ArrayBuffer':
                        continue
                    candidates = enumerate(signatures[signature_index + 1:],
                                           signature_index + 1)
                    for candidate_index, candidate in candidates:
                        if len(candidate) <= argument_position:
                            continue
                        if candidate[
                                argument_position].type.id != 'ArrayBufferView':
                            continue
                        if len(index_swaps):
                            raise Exception(
                                'Cannot deal with more than a single swap')
                        index_swaps[candidate_index] = signature_index
                        index_swaps[signature_index] = candidate_index

            for signature_index in range(len(signatures)):
                signature_index = index_swaps.get(signature_index,
                                                  signature_index)
                signature = signatures[signature_index]
                for argument_position, argument in enumerate(signature):
                    if is_optional(signature_index, argument):
                        GenerateChecksAndCall(signature_index,
                                              argument_position)
                GenerateChecksAndCall(signature_index, len(signature))
            body_emitter.Emit(
                '    throw new ArgumentError("Incorrect number or type of arguments");'
                '\n')
        else:
            signature = signatures[0]
            argument_count = len(signature)
            for argument_position, argument in list(enumerate(signature))[::-1]:
                if is_optional(0, argument):
                    check = '%s != null' % parameter_names[argument_position]
                    # argument_count instead of argument_position + 1 is used here to cover one
                    # complicated case with the effectively optional argument in the middle.
                    # Consider foo(x, optional y, [Default=NullString] optional z)
                    # (as of now it's modelled after HTMLMediaElement.webkitAddKey).
                    # y is optional in WebCore, while z is not.
                    # In this case, if y was actually passed, we'd like to emit foo(x, y, z) invocation,
                    # not foo(x, y).
                    GenerateCall(0, argument_count, [check])
                    argument_count = argument_position
            GenerateCall(0, argument_count, [])

    def _GenerateDispatcherBody(self,
                                info,
                                operations,
                                declaration,
                                generate_call,
                                is_optional,
                                can_omit_type_check=lambda type, pos: False):

        def GenerateCall(stmts_emitter, call_emitter, version, signature_index,
                         argument_count):
            generate_call(stmts_emitter, call_emitter, version,
                          operations[signature_index], argument_count)

        def IsOptional(signature_index, argument):
            return is_optional(argument)

        emitter = self._members_emitter

        self._GenerateOverloadDispatcher(
            info, [operation.arguments for operation in operations],
            operations[0].type.id == 'void', declaration, GenerateCall,
            IsOptional, emitter, can_omit_type_check)

    def AdditionalImplementedInterfaces(self):
        # TODO: Include all implemented interfaces, including other Lists.
        implements = []
        if self._interface_type_info.list_item_type():
            item_type = self._type_registry.TypeInfo(
                self._interface_type_info.list_item_type()).dart_type()
            if self._interface_type_info.list_item_type_nullable():
                item_type += '?'
            implements.append('List<%s>' % item_type)
        return implements

    def Mixins(self):
        mixins = []
        if self._interface_type_info.list_item_type():
            item_type = self._type_registry.TypeInfo(
                self._interface_type_info.list_item_type()).dart_type()
            if self._interface_type_info.list_item_type_nullable():
                item_type += '?'
            mixins.append('ListMixin<%s>' % item_type)
            mixins.append('ImmutableListMixin<%s>' % item_type)

        return mixins

    def AddConstructors(self, constructors, factory_name,
                        factory_constructor_name):
        """ Adds all of the constructors.
    Arguments:
      constructors - List of the constructors to be added.
      factory_name - Name of the factory for this class.
      factory_constructor_name - The name of the constructor on the
          factory_name to call (calls an autogenerated FactoryProvider
          if unspecified)
    """
        for constructor_info in constructors:
            self._AddConstructor(constructor_info, factory_name,
                                 factory_constructor_name)

    def _AddConstructor(self, constructor_info, factory_name,
                        factory_constructor_name):
        # Hack to ignore the constructor used by JavaScript.
        if ((self._interface.id == 'HTMLImageElement' or
             self._interface.id == 'Blob' or
             self._interface.id == 'DOMException') and
                not constructor_info.pure_dart_constructor):
            return

        if self.GenerateCustomFactory(constructor_info):
            return

        metadata = self._metadata.GetFormattedMetadata(
            self._library_name, self._interface, self._interface.id, '  ')

        if not factory_constructor_name:
            factory_constructor_name = '_create'
            factory_parameters = constructor_info.ParametersAsArgumentList()
        else:
            factory_parameters = ', '.join(constructor_info.factory_parameters)

        def InputType(type_name):
            conversion = self._InputConversion(type_name,
                                               constructor_info.declared_name)
            if conversion:
                return conversion.input_type
            else:
                return self._NarrowInputType(
                    type_name) if type_name else 'dynamic'

        if constructor_info.pure_dart_constructor:
            # TODO(antonm): use common dispatcher generation for this case as well.
            has_optional = any(param_info.is_optional
                               for param_info in constructor_info.param_infos)
            factory_call = self.MakeFactoryCall(
                factory_name, factory_constructor_name, factory_parameters,
                constructor_info)
            if not has_optional:
                self._members_emitter.Emit(
                    '\n  $(METADATA)'
                    'factory $CTOR($PARAMS) => '
                    '$FACTORY_CALL;\n',
                    CTOR=constructor_info._ConstructorFullName(self._DartType),
                    PARAMS=constructor_info.ParametersAsDeclaration(InputType),
                    FACTORY_CALL=factory_call,
                    METADATA=metadata)
            else:
                inits = self._members_emitter.Emit(
                    '\n  $(METADATA)'
                    'factory $CONSTRUCTOR($PARAMS) {\n'
                    '    $CONSTRUCTOR e = $FACTORY_CALL;\n'
                    '$!INITS'
                    '    return e;\n'
                    '  }\n',
                    CONSTRUCTOR=constructor_info._ConstructorFullName(
                        self._DartType),
                    METADATA=metadata,
                    FACTORY_CALL=factory_call,
                    PARAMS=constructor_info.ParametersAsDeclaration(InputType))

                for index, param_info in enumerate(
                        constructor_info.param_infos):
                    if param_info.is_optional:
                        inits.Emit(
                            '    if ($E != null) e.$E = $E;\n',
                            E=param_info.name)
        else:
            custom_factory_ctr = self._interface.id in _custom_factories
            if self._interface_type_info.has_generated_interface():
                constructor_full_name = constructor_info._ConstructorFullName(
                    self._DartType)
            else:
                # The interface is suppress_interface so use the implementation_name not
                # the dart_type.
                constructor_full_name = self._interface_type_info.implementation_name(
                )
                factory_name = constructor_full_name

            def GenerateCall(stmts_emitter, call_emitter, version,
                             signature_index, argument_count):
                name = emitter.Format('_create_$VERSION', VERSION=version)
                arguments = constructor_info.idl_args[
                    signature_index][:argument_count]
                args = None
                call_template = ''
                if self._dart_use_blink:
                    type_ids = [p.type.id for p in arguments]
                    base_name, rs = \
                        self.DeriveNativeEntry("constructorCallback", 'Constructor', argument_count)
                    qualified_name = \
                        self.DeriveQualifiedBlinkName(self._interface.id,
                                                      base_name)
                    args = constructor_info.ParametersAsArgumentList(
                        argument_count)

                    # Handle converting Maps to Dictionaries, etc.
                    (factory_params, converted_arguments,
                     calling_params) = self._ConvertArgumentTypes(
                         stmts_emitter, arguments, argument_count,
                         constructor_info)
                    args = ', '.join(converted_arguments)
                    call_template = '$FACTORY_NAME($FACTORY_PARAMS)'
                else:
                    qualified_name = emitter.Format(
                        '$FACTORY.$NAME', FACTORY=factory_name, NAME=name)
                    (factory_params, converted_arguments,
                     calling_params) = self._ConvertArgumentTypes(
                         stmts_emitter, arguments, argument_count,
                         constructor_info)
                    args = ', '.join(converted_arguments)
                    call_template = '$FACTORY_NAME($FACTORY_PARAMS)'
                call_emitter.Emit(
                    call_template,
                    FACTORY_NAME=qualified_name,
                    FACTORY_PARAMS=args)
                self.EmitStaticFactoryOverload(constructor_info, name,
                                               arguments)

            def IsOptional(signature_index, argument):
                return self.IsConstructorArgumentOptional(argument)

            entry_declaration = emitter.Format(
                '$(METADATA)$FACTORY_KEYWORD $CTOR($PARAMS)',
                FACTORY_KEYWORD=('factory' if not custom_factory_ctr else
                                 'static %s' % constructor_full_name),
                CTOR=(('' if not custom_factory_ctr else '_factory') +
                      constructor_full_name),
                METADATA=metadata,
                PARAMS=constructor_info.ParametersAsDeclaration(InputType))

            overload_emitter = self._members_emitter
            overload_declaration = entry_declaration

            self._GenerateOverloadDispatcher(constructor_info,
                                             constructor_info.idl_args, False,
                                             overload_declaration, GenerateCall,
                                             IsOptional, overload_emitter)

    def _AddFutureifiedOperation(self, info, html_name):
        """Given a API function that uses callbacks, convert it to using Futures.

    This conversion assumes the success callback is always provided before the
    error callback (and so far in the DOM API, this is the case)."""
        callback_info = GetCallbackInfo(
            self._database.GetInterface(info.callback_args[0].type_id))

        # Generated private members never have named arguments.
        ignore_named_parameters = True if html_name.startswith('_') else False

        # If more than one callback then the second argument is the error callback.
        # Some error callbacks have 2 args (e.g., executeSql) where the second arg
        # is the error - this is the argument we want.
        error_callback = ""
        if len(info.callback_args) > 1:
            error_callback_info = GetCallbackInfo(
                self._database.GetInterface(info.callback_args[1].type_id))
            error_callbackNames = []
            for paramInfo in error_callback_info.param_infos:
                error_callbackNames.append(paramInfo.name)
            errorCallbackVariables = ", ".join(error_callbackNames)
            errorName = error_callback_info.param_infos[-1].name
            error_callback = (
                ',\n        %s(%s) { completer.completeError(%s); }' % (
                    ('%s : ' % info.callback_args[1].name
                     if info.requires_named_arguments and
                     info.callback_args[1].is_optional and
                     not (ignore_named_parameters) else ''),
                    errorCallbackVariables, errorName))

        extensions = GetDDC_Extension(self._interface, info.declared_name)
        if extensions:
            ddc_extensions = "\n".join(extensions)
        else:
            ddc_extensions = ''

        # Some callbacks have more than one parameters.  If so use all of
        # those parameters.  However, if more than one argument use the
        # type of the last argument to be returned e.g., executeSql the callback
        # is (transaction, resultSet) and only the resultSet is returned SqlResultSet.
        callbackArgsLen = len(callback_info.param_infos)
        future_generic = ''
        callbackVariables = ''
        completerVariable = ''
        if callbackArgsLen == 1:
            callbackVariables = 'value'
            completerVariable = callbackVariables
            if callback_info.param_infos[0].type_id:
                future_generic = '<%s>' % self._DartType(
                    callback_info.param_infos[0].type_id)
        elif callbackArgsLen > 1:
            callbackNames = []
            for paramInfo in callback_info.param_infos:
                callbackNames.append(paramInfo.name)
            callbackVariables = ",".join(callbackNames)
            completerVariable = callbackNames[-1]
            future_generic = '<%s>' % self._DartType(
                callback_info.param_infos[-1].type_id)

        param_list = info.ParametersAsArgumentList(None,
                                                   ignore_named_parameters)
        dictionary_argument = info.dictionaryArgumentName()

        convert_map = ''
        if dictionary_argument is not None:
            mapArg = dictionary_argument[0]
            tempVariable = '%s_dict' % mapArg
            mapArgOptional = dictionary_argument[1]

            if not (extensions):
                if not (param_list.endswith(', mapArg') or
                        param_list.endswith(', options') or
                        param_list == mapArg):
                    print "ERROR: %s.%s - Last parameter or only parameter %s is not of type Map" % (
                        self._interface.id, html_name, mapArg)
                param_list = '%s_dict' % param_list

                if mapArgOptional:
                    convert_map = '    var %s = null;\n'\
                                  '    if (%s != null) {\n'\
                                  '      %s = convertDartToNative_Dictionary(%s);\n'\
                                  '    }\n' % (tempVariable, mapArg, tempVariable, mapArg)
                else:
                    convert_map = '    var %s = convertDartToNative_Dictionary(%s);\n' % (
                        tempVariable, mapArg)

        metadata = ''
        if '_RenamingAnnotation' in dir(self):
            metadata = (
                self._RenamingAnnotation(info.declared_name, html_name) +
                self._Metadata(info.type_name, info.declared_name, None,
                    info.type_nullable))
        self._members_emitter.Emit(
            '\n'
            '  $METADATA$MODIFIERS$TYPE$FUTURE_GENERIC $NAME($PARAMS) {\n'
            '    $CONVERT_DICTIONARY'
            '    var completer = new Completer$(FUTURE_GENERIC)();\n'
            '    $ORIGINAL_FUNCTION($PARAMS_LIST\n'
            '        $NAMED_PARAM($VARIABLE_NAME) { '
            '$DDC_EXTENSION\n'
            'completer.complete($COMPLETER_NAME); }'
            '$ERROR_CALLBACK);\n'
            '    return completer.future;\n'
            '  }\n',
            METADATA=metadata,
            MODIFIERS='static ' if info.IsStatic() else '',
            TYPE=self.SecureOutputType(info.type_name,
                nullable=info.type_nullable),
            NAME=html_name[1:],
            PARAMS=info.
            ParametersAsDeclaration(self._NarrowInputType if '_NarrowInputType'
                                    in dir(self) else self._DartType),
            CONVERT_DICTIONARY=convert_map,
            PARAMS_LIST='' if param_list == '' else param_list + ',',
            NAMED_PARAM=('%s : ' % info.callback_args[0].name
                         if info.requires_named_arguments and
                         info.callback_args[0].is_optional and
                         not (ignore_named_parameters) else ''),
            VARIABLE_NAME=callbackVariables,
            COMPLETER_NAME=completerVariable,
            DDC_EXTENSION=ddc_extensions,
            ERROR_CALLBACK=error_callback,
            FUTURE_GENERIC=future_generic,
            ORIGINAL_FUNCTION=html_name)

    def EmitHelpers(self, base_class):
        if not self._members_emitter:
            return

        if self._interface.id not in custom_html_constructors:
            self._members_emitter.Emit(
                '  // To suppress missing implicit constructor warnings.\n'
                '  factory $CLASSNAME._() { '
                'throw new UnsupportedError("Not supported"); }\n',
                CLASSNAME=self._interface_type_info.implementation_name())

    def DeclareAttribute(self, attribute, attr_name, read_only):
        """ Declares an attribute but does not include the code to invoke it.
    """
        if read_only:
            # HACK(terry): Element is not abstract for Dartium so isContentEditable
            # must have a body see impl_Element.darttemplate
            if (self._interface.id == 'Element' and
                    attr_name == 'isContentEditable' and self._dart_js_interop):
                return
            else:
                template = '\n  $TYPE get $NAME;\n'
        else:
            template = '\n  $TYPE get $NAME native;\n' \
                       '\n  set $NAME($TYPE value) native;\n'

        # Nullability is determined by attribute compatibility.
        is_compat = self._mdn_reader.is_compatible(attribute)
        nullable = attribute.type.nullable or not is_compat

        self._members_emitter.Emit(template,
                                   NAME=attr_name,
                                   TYPE=self.SecureOutputType(
                                       attribute.type.id, nullable=nullable))

    def DeclareOperation(self, operation, return_type_name, method_name):
        """ Declares an operation but does not include the code to invoke it.
    Arguments:
      operation - The operation to be declared.
      return_type_name - The name of the return type.
      method_name - The name of the method.
    """
        # HACK(terry): Element is not abstract for Dartium so click
        # must have a body see impl_Element.darttemplate
        if (self._interface.id == 'Element' and method_name == 'click' and
                self._dart_js_interop):
            return
        else:
            template = '\n  $TYPE $NAME($PARAMS);\n'

        self._members_emitter.Emit(
            template,
            TYPE=return_type_name,
            NAME=method_name,
            PARAMS=operation.ParametersAsDeclaration(self._DartType))

    def EmitListMixin(self, element_name, nullable):
        # TODO(sra): Use separate mixins for mutable implementations of List<T>.
        # TODO(sra): Use separate mixins for typed array implementations of List<T>.
        template_file = 'immutable_list_mixin.darttemplate'
        has_length = False
        has_length_setter = False

        def _HasExplicitIndexedGetter(self):
            return any(op.id == 'getItem' for op in self._interface.operations)

        def _HasCustomIndexedGetter(self):
            return 'CustomIndexedGetter' in self._interface.ext_attrs

        def _HasNativeIndexedGetter(self):
            return not (_HasCustomIndexedGetter(self) or
                        _HasExplicitIndexedGetter(self))

        if _HasExplicitIndexedGetter(self):
            getter_name = 'getItem'
        else:
            getter_name = '_nativeIndexedGetter'

        for attr in self._interface.attributes:
            if attr.id == 'length':
                has_length = True
                has_length_setter = not attr.is_read_only

        has_num_items = any(
            attr.id == 'numberOfItems' for attr in self._interface.attributes)

        template = self._template_loader.Load(
            template_file, {
                'DEFINE_LENGTH_AS_NUM_ITEMS':
                not has_length and has_num_items,
                'DEFINE_LENGTH_SETTER':
                not has_length_setter,
                'USE_NATIVE_INDEXED_GETTER':
                _HasNativeIndexedGetter(self) or
                _HasExplicitIndexedGetter(self),
            })
        if nullable:
            element_js = element_name + "|Null"
            element_name += '?'
        else:
            element_js = element_name
        self._members_emitter.Emit(
            template, E=element_name, EJS=element_js, GETTER=getter_name)

    def SecureOutputType(self,
                         type_name,
                         is_dart_type=False,
                         can_narrow_type=False,
                         nullable=False):
        """ Converts the type name to the secure type name for return types.
    Arguments:
      can_narrow_type - True if the output type can be narrowed further than
        what would be accepted for input, used to narrow num APIs down to double
        or int.
    """
        if is_dart_type:
            dart_name = type_name
        else:
            type_info = self._TypeInfo(type_name)
            dart_name = type_info.dart_type()
            if can_narrow_type and dart_name == 'num':
                dart_name = type_info.native_type()

        # We only need to secure Window.  Only local History and Location are
        # returned in generated code.
        assert (dart_name != 'HistoryBase' and dart_name != 'LocationBase')
        if dart_name == 'Window':
            dart_name = _secure_base_types[dart_name]
        if type_name == 'any':
            dart_name = 'Object'
        if nullable and dart_name != 'dynamic':
            dart_name = dart_name + '?'
        return dart_name

    def SecureBaseName(self, type_name):
        if type_name in _secure_base_types:
            return _secure_base_types[type_name]

    def is_DOM_type(self, type_name):
        try:
            self._type_registry.TypeInfo(type_name)
            return True
        except RuntimeError:
            return False

    def _NarrowToImplementationType(self, type_name):
        return self._type_registry.TypeInfo(type_name).narrow_dart_type()

    def _NarrowInputType(self, type_name):
        return self._NarrowToImplementationType(type_name)

    def _DartType(self, type_name):
        return self._type_registry.DartType(type_name)

    def _TypeInfo(self, type_name):
        return self._type_registry.TypeInfo(type_name)

    def _CallbackConvert(self, argType, info):
        if self._database.HasInterface(argType):
            interface = self._database.GetInterface(argType)
            if "Callback" in interface.ext_attrs:
                return interface.ext_attrs['Callback']
        return None

    def _ConvertArgumentTypes(self, stmts_emitter, arguments, argument_count,
                              info):
        temp_version = [0]
        converted_arguments = []
        target_parameters = []
        calling_parameters = []
        for position, arg in enumerate(arguments[:argument_count]):
            callBackInfo = self._CallbackConvert(
                arg.type.id, info)  # Returns callback arity (# of parameters)
            if callBackInfo is None:
                conversion = self._InputConversion(arg.type.id,
                                                   info.declared_name)
            else:
                conversion = self._InputConversion('Callback',
                                                   info.declared_name)

            param_name = arguments[position].id
            if conversion:
                temp_version[0] += 1
                temp_name = '%s_%s' % (param_name, temp_version[0])
                temp_type = conversion.output_type
                null_assert_needed = info.param_infos[position].is_nullable \
                    and not conversion.nullable_input
                stmts_emitter.Emit(
                    '$(INDENT)$TYPE $NAME = $CONVERT($ARG$NULLASSERT);\n'
                    if callBackInfo is None else
                    '$(INDENT)$TYPE $NAME = $CONVERT($ARG$NULLASSERT, $ARITY);\n',
                    TYPE=TypeOrVar(temp_type),
                    NAME=temp_name,
                    CONVERT=conversion.function_name,
                    ARG=info.param_infos[position].name,
                    NULLASSERT='!' if null_assert_needed else '',
                    ARITY=callBackInfo)
                converted_arguments.append(temp_name)
                param_type = temp_type
                verified_type = temp_type  # verified by assignment in checked mode.
            else:
                converted_arguments.append(info.param_infos[position].name)
                if self._database.HasTypeDef(arg.type.id):
                    param_type = 'dynamic'
                else:
                    param_type = self._NarrowInputType(arg.type.id)
                    # Verified by argument checking on entry to the dispatcher.

                    verified_type = self._InputType(
                        info.param_infos[position].type_id, info)
                    # The native method does not need an argument type if we know the type.
                    # But we do need the native methods to have correct function types, so
                    # be conservative.
                    if param_type == verified_type:
                        if param_type in [
                                'String', 'num', 'int', 'double', 'bool',
                                'Object'
                        ]:
                            param_type = 'dynamic'
            arg_is_nullable = arg.type.nullable
            # If the parameter is either nullable or optional with no non-null
            # default value, it is nullable.
            if (info.param_infos[position].is_optional and
                (info.param_infos[position].default_value_is_null == True or
                 info.param_infos[position].default_value == None)
               ) or info.param_infos[position].is_nullable:
                arg_is_nullable = True
            target_parameters.append(
                '%s%s' % (TypeOrNothing(param_type, nullable=arg_is_nullable),
                          param_name))
            calling_parameters.append(',%s ' % param_name)

        return target_parameters, converted_arguments, calling_parameters

    def _InputType(self, type_name, info):
        conversion = self._InputConversion(type_name, info.declared_name)
        if conversion:
            return conversion.input_type
        else:
            # If typedef it's a union return dynamic.
            if self._database.HasTypeDef(type_name):
                return 'dynamic'
            else:
                return self._NarrowInputType(
                    type_name) if type_name else 'dynamic'
