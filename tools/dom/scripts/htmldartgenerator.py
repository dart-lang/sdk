#!/usr/bin/python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""This module provides shared functionality for the system to generate
dart:html APIs from the IDL database."""

import emitter
from generator import AnalyzeOperation, ConstantOutputOrder, \
    DartDomNameOfAttribute, FindMatchingAttribute, IsDartCollectionType, \
    IsPureInterface, TypeOrNothing, ConvertToFuture, GetCallbackInfo
from htmlrenamer import convert_to_future_members

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
  def __init__(self, interface, options):
    self._database = options.database
    self._interface = interface
    self._type_registry = options.type_registry
    self._interface_type_info = self._type_registry.TypeInfo(self._interface.id)
    self._renamer = options.renamer
    self._metadata = options.metadata
    self._library_name = self._renamer.GetLibraryName(self._interface)

  def EmitSupportCheck(self):
    if self.HasSupportCheck():
      check = self.GetSupportCheck()
      if type(check) != tuple:
        signature = 'get supported'
      else:
        signature = check[0]
        check = check[1]
      self._members_emitter.Emit('\n'
          '  /// Checks if this type is supported on the current platform.\n'
          '  static bool $SIGNATURE => $SUPPORT_CHECK;\n',
          SIGNATURE=signature, SUPPORT_CHECK=check)

  def EmitEventGetter(self, events_class_name):
    self._members_emitter.Emit(
        "\n  @DocsEditable"
        "\n  @DomName('EventTarget.addEventListener, "
        "EventTarget.removeEventListener, EventTarget.dispatchEvent')"
        "\n  @deprecated"
        "\n  $TYPE get on =>\n    new $TYPE(this);\n",
        TYPE=events_class_name)

  def AddMembers(self, interface, declare_only=False):
    for const in sorted(interface.constants, ConstantOutputOrder):
      self.AddConstant(const)

    for attr in sorted(interface.attributes, ConstantOutputOrder):
      if attr.type.id != 'EventListener':
        self.AddAttribute(attr, declare_only)

    # The implementation should define an indexer if the interface directly
    # extends List.
    element_type = None
    requires_indexer = False
    if self._interface_type_info.list_item_type():
      self.AddIndexer(self._interface_type_info.list_item_type())
    else:
      for parent in self._database.Hierarchy(self._interface):
        if parent == self._interface:
          continue
        parent_type_info = self._type_registry.TypeInfo(parent.id)
        if parent_type_info.list_item_type():
          self.AmendIndexer(parent_type_info.list_item_type())
          break

    # Group overloaded operations by name.
    operationsByName = self._OperationsByName(interface)

    # Generate operations.
    for id in sorted(operationsByName.keys()):
      operations = operationsByName[id]
      info = AnalyzeOperation(interface, operations)
      self.AddOperation(info, declare_only)
      if ('%s.%s' % (interface.id, info.declared_name) in
          convert_to_future_members):
        self.AddOperation(ConvertToFuture(info), declare_only)

  def AddSecondaryMembers(self, interface):
    # With multiple inheritance, attributes and operations of non-first
    # interfaces need to be added.  Sometimes the attribute or operation is
    # defined in the current interface as well as a parent.  In that case we
    # avoid making a duplicate definition and pray that the signatures match.
    secondary_parents = self._TransitiveSecondaryParents(interface)
    for parent_interface in sorted(secondary_parents):
      if isinstance(parent_interface, str):
        continue
      for attr in sorted(parent_interface.attributes, ConstantOutputOrder):
        if not FindMatchingAttribute(interface, attr):
          self.SecondaryContext(parent_interface)
          self.AddAttribute(attr)

      # Group overloaded operations by name.
      operationsByName =self._OperationsByName(parent_interface)

      # Generate operations.
      for id in sorted(operationsByName.keys()):
        if not any(op.id == id for op in interface.operations):
          operations = operationsByName[id]
          info = AnalyzeOperation(interface, operations)
          self.SecondaryContext(parent_interface)
          self.AddOperation(info)

  def _OperationsByName(self, interface):
    operationsByName = {}
    for operation in interface.operations:
      name = operation.ext_attrs.get('DartName', operation.id)
      operationsByName.setdefault(name, []).append(operation)
    return operationsByName

  def AddConstant(self, constant):
    const_name = self._renamer.RenameMember(
        self._interface.id, constant, constant.id, 'get:', dartify_name=False)
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
    attr_name = self._renamer.RenameMember(
      self._interface.id, attribute, dom_name, 'get:')
    if not attr_name:
      return

    html_setter_name = self._renamer.RenameMember(
        self._interface.id, attribute, dom_name, 'set:')
    read_only = (attribute.is_read_only or 'Replaceable' in attribute.ext_attrs
                 or not html_setter_name)

    # We don't yet handle inconsistent renames of the getter and setter yet.
    assert(not html_setter_name or attr_name == html_setter_name)

    if declare_only:
      self.DeclareAttribute(attribute,
          self.SecureOutputType(attribute.type.id), attr_name, read_only)
    else:
      self.EmitAttribute(attribute, attr_name, read_only)

  def AddOperation(self, info, declare_only=False):
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
    method_name = self._renamer.RenameMember(self._interface.id,
                                             info.operations[0],
                                             info.name,
                                             'call:')
    if not method_name:
      if info.name == 'item':
        # FIXME: item should be renamed to operator[], not removed.
        self.EmitOperation(info, '_item')
      return

    if declare_only:
      self.DeclareOperation(info,
          self.SecureOutputType(info.type_name), method_name)
    else:
      self.EmitOperation(info, method_name)

  def _GenerateOverloadDispatcher(self,
      info,
      signatures,
      is_void,
      declaration,
      generate_call,
      is_optional,
      can_omit_type_check=lambda type, pos: False):

    parameter_names = [p.name for p in info.param_infos]
    number_of_required_in_dart = info.NumberOfRequiredInDart()

    body_emitter = self._members_emitter.Emit(
        '\n'
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
            '$!STMTS$!CALL',
            INDENT='    ');

      if is_void:
        call_emitter = call_emitter.Emit('$(INDENT)$!CALL;\n$(INDENT)return;\n')
      else:
        call_emitter = call_emitter.Emit('$(INDENT)return $!CALL;\n')

      version[0] += 1
      generate_call(stmts_emitter, call_emitter,
          version[0], signature_index, argument_count)

    def GenerateChecksAndCall(signature_index, argument_count):
      checks = []
      for i in reversed(range(0, argument_count)):
        argument = signatures[signature_index][i]
        parameter_name = parameter_names[i]
        test_type = self._DartType(argument.type.id)

        if test_type in ['dynamic', 'Object']:
          checks.append('%s != null' % parameter_name)
        elif not can_omit_type_check(test_type, i):
          checks.append('(%s is %s || %s == null)' % (
              parameter_name, test_type, parameter_name))
        elif i >= number_of_required_in_dart:
          checks.append('%s != null' % parameter_name)

      # There can be multiple presence checks.  We need them all since a later
      # optional argument could have been passed by name, leaving 'holes'.
      checks.extend(['%s == null' % name for name in parameter_names[argument_count:]])

      GenerateCall(signature_index, argument_count, checks)

    # TODO: Optimize the dispatch to avoid repeated checks.
    if len(signatures) > 1:
      index_swaps = {}
      for signature_index, signature in enumerate(signatures):
        for argument_position, argument in enumerate(signature):
          if argument.type.id != 'ArrayBuffer':
            continue
          candidates = enumerate(
              signatures[signature_index + 1:], signature_index + 1)
          for candidate_index, candidate in candidates:
            if len(candidate) <= argument_position:
              continue
            if candidate[argument_position].type.id != 'ArrayBufferView':
              continue
            if len(index_swaps):
              raise Exception('Cannot deal with more than a single swap')
            index_swaps[candidate_index] = signature_index
            index_swaps[signature_index] = candidate_index

      for signature_index in range(len(signatures)):
        signature_index = index_swaps.get(signature_index, signature_index)
        signature = signatures[signature_index]
        for argument_position, argument in enumerate(signature):
          if is_optional(signature_index, argument):
            GenerateChecksAndCall(signature_index, argument_position)
        GenerateChecksAndCall(signature_index, len(signature))
      body_emitter.Emit(
          '    throw new ArgumentError("Incorrect number or type of arguments");'
          '\n');
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

    def GenerateCall(
        stmts_emitter, call_emitter, version, signature_index, argument_count):
      generate_call(
          stmts_emitter, call_emitter,
          version, operations[signature_index], argument_count)

    def IsOptional(signature_index, argument):
      return is_optional(operations[signature_index], argument)

    self._GenerateOverloadDispatcher(
        info,
        [operation.arguments for operation in operations],
        operations[0].type.id == 'void',
        declaration,
        GenerateCall,
        IsOptional,
        can_omit_type_check)

  def AdditionalImplementedInterfaces(self):
    # TODO: Include all implemented interfaces, including other Lists.
    implements = []
    if self._interface_type_info.list_item_type():
      item_type_info = self._type_registry.TypeInfo(
          self._interface_type_info.list_item_type())
      implements.append('List<%s>' % item_type_info.dart_type())
    return implements

  def Mixins(self):
    mixins = []
    if self._interface_type_info.list_item_type():
      item_type = self._type_registry.TypeInfo(
          self._interface_type_info.list_item_type()).dart_type()
      mixins.append('ListMixin<%s>' % item_type)
      mixins.append('ImmutableListMixin<%s>' % item_type)

    return mixins


  def AddConstructors(self,
      constructors, factory_name, factory_constructor_name):
    """ Adds all of the constructors.
    Arguments:
      constructors - List of the constructors to be added.
      factory_name - Name of the factory for this class.
      factory_constructor_name - The name of the constructor on the
          factory_name to call (calls an autogenerated FactoryProvider
          if unspecified)
    """
    for constructor_info in constructors:
      self._AddConstructor(
          constructor_info, factory_name, factory_constructor_name)

  def _AddConstructor(self,
      constructor_info, factory_name, factory_constructor_name):
    if self.GenerateCustomFactory(constructor_info):
      return

    metadata = self._metadata.GetFormattedMetadata(
        self._library_name, self._interface, self._interface.id, '  ')

    if not factory_constructor_name:
      factory_constructor_name = '_create'
      factory_parameters = constructor_info.ParametersAsArgumentList()
    else:
      factory_parameters = ', '.join(constructor_info.factory_parameters)

    if constructor_info.pure_dart_constructor:
      # TODO(antonm): use common dispatcher generation for this case as well.
      has_optional = any(param_info.is_optional
          for param_info in constructor_info.param_infos)

      if not has_optional:
        self._members_emitter.Emit(
            '\n  $(METADATA)'
            'factory $CTOR($PARAMS) => '
            '$FACTORY.$CTOR_FACTORY_NAME($FACTORY_PARAMS);\n',
            CTOR=constructor_info._ConstructorFullName(self._DartType),
            PARAMS=constructor_info.ParametersDeclaration(self._DartType),
            FACTORY=factory_name,
            METADATA=metadata,
            CTOR_FACTORY_NAME=factory_constructor_name,
            FACTORY_PARAMS=factory_parameters)
      else:
        inits = self._members_emitter.Emit(
            '\n  $(METADATA)'
            'factory $CONSTRUCTOR($PARAMS) {\n'
            '    var e = $FACTORY.$CTOR_FACTORY_NAME($FACTORY_PARAMS);\n'
            '$!INITS'
            '    return e;\n'
            '  }\n',
            CONSTRUCTOR=constructor_info._ConstructorFullName(self._DartType),
            METADATA=metadata,
            FACTORY=factory_name,
            CTOR_FACTORY_NAME=factory_constructor_name,
            PARAMS=constructor_info.ParametersDeclaration(self._DartType),
            FACTORY_PARAMS=factory_parameters)

        for index, param_info in enumerate(constructor_info.param_infos):
          if param_info.is_optional:
            inits.Emit('    if ($E != null) e.$E = $E;\n', E=param_info.name)
    else:
      def GenerateCall(
          stmts_emitter, call_emitter,
          version, signature_index, argument_count):
        name = emitter.Format('_create_$VERSION', VERSION=version)
        call_emitter.Emit('$FACTORY.$NAME($FACTORY_PARAMS)',
            FACTORY=factory_name,
            NAME=name,
            FACTORY_PARAMS= \
                constructor_info.ParametersAsArgumentList(argument_count))
        self.EmitStaticFactoryOverload(
            constructor_info, name,
            constructor_info.idl_args[signature_index][:argument_count])

      def IsOptional(signature_index, argument):
        return self.IsConstructorArgumentOptional(argument)

      custom_factory_ctr = self._interface.id in _custom_factories
      constructor_full_name = constructor_info._ConstructorFullName(
          self._DartType)
      self._GenerateOverloadDispatcher(
          constructor_info,
          constructor_info.idl_args,
          False,
          emitter.Format('$(METADATA)$FACTORY_KEYWORD $CTOR($PARAMS)',
            FACTORY_KEYWORD=('factory' if not custom_factory_ctr else
                'static %s' % constructor_full_name),
            CTOR=(('' if not custom_factory_ctr else '_factory')
                + constructor_full_name),
            METADATA=metadata,
            PARAMS=constructor_info.ParametersDeclaration(self._DartType)),
          GenerateCall,
          IsOptional)

  def _AddFutureifiedOperation(self, info, html_name):
    """Given a API function that uses callbacks, convert it to using Futures.

    This conversion assumes the success callback is always provided before the
    error callback (and so far in the DOM API, this is the case)."""
    callback_info = GetCallbackInfo(
        self._database.GetInterface(info.callback_args[0].type_id))

    param_list = info.ParametersAsArgumentList()
    metadata = ''
    if '_RenamingAnnotation' in dir(self):
      metadata = (self._RenamingAnnotation(info.declared_name, html_name) +
          self._Metadata(info.type_name, info.declared_name, None))
    self._members_emitter.Emit(
        '\n'
        '  $METADATA$MODIFIERS$TYPE$FUTURE_GENERIC $NAME($PARAMS) {\n'
        '    var completer = new Completer$(FUTURE_GENERIC)();\n'
        '    $ORIGINAL_FUNCTION($PARAMS_LIST\n'
        '        $NAMED_PARAM($VARIABLE_NAME) { '
        'completer.complete($VARIABLE_NAME); }'
        '$ERROR_CALLBACK);\n'
        '    return completer.future;\n'
        '  }\n',
        METADATA=metadata,
        MODIFIERS='static ' if info.IsStatic() else '',
        TYPE=self.SecureOutputType(info.type_name),
        NAME=html_name[1:],
        PARAMS=info.ParametersDeclaration(self._NarrowInputType
            if '_NarrowInputType' in dir(self) else self._DartType),
        PARAMS_LIST='' if param_list == '' else param_list + ',',
        NAMED_PARAM=('%s : ' % info.callback_args[0].name
            if info.requires_named_arguments and
              info.callback_args[0].is_optional else ''),
        VARIABLE_NAME= '' if len(callback_info.param_infos) == 0 else 'value',
        ERROR_CALLBACK=('' if len(info.callback_args) == 1 else
            (',\n        %s(error) { completer.completeError(error); }' %
            ('%s : ' % info.callback_args[1].name
            if info.requires_named_arguments and
                info.callback_args[1].is_optional else ''))),
        FUTURE_GENERIC = ('' if len(callback_info.param_infos) == 0 or
            not callback_info.param_infos[0].type_id else
            '<%s>' % self._DartType(callback_info.param_infos[0].type_id)),
        ORIGINAL_FUNCTION = html_name)

  def EmitHelpers(self, base_class):
    if not self._members_emitter:
      return

    if base_class != self.RootClassName():
      self._members_emitter.Emit(
          '  // To suppress missing implicit constructor warnings.\n'
          '  factory $CLASSNAME._() { '
          'throw new UnsupportedError("Not supported"); }\n',
          CLASSNAME=self._interface_type_info.implementation_name())

  def DeclareAttribute(self, attribute, type_name, attr_name, read_only):
    """ Declares an attribute but does not include the code to invoke it.
    """
    if read_only:
      template = '\n  $TYPE get $NAME;\n'
    else:
      template = '\n  $TYPE $NAME;\n'

    self._members_emitter.Emit(template,
        NAME=attr_name,
        TYPE=type_name)

  def DeclareOperation(self, operation, return_type_name, method_name):
    """ Declares an operation but does not include the code to invoke it.
    Arguments:
      operation - The operation to be declared.
      return_type_name - The name of the return type.
      method_name - The name of the method.
    """
    self._members_emitter.Emit(
             '\n'
             '  $TYPE $NAME($PARAMS);\n',
             TYPE=return_type_name,
             NAME=method_name,
             PARAMS=operation.ParametersDeclaration(self._DartType))

  def EmitListMixin(self, element_name):
    # TODO(sra): Use separate mixins for mutable implementations of List<T>.
    # TODO(sra): Use separate mixins for typed array implementations of List<T>.
    template_file = 'immutable_list_mixin.darttemplate'
    has_length = False
    has_length_setter = False

    for attr in self._interface.attributes:
      if attr.id == 'length':
        has_length = True
        has_length_setter = not attr.is_read_only

    has_num_items = any(attr.id == 'numberOfItems'
        for attr in self._interface.attributes)

    template = self._template_loader.Load(
        template_file,
        {
          'DEFINE_LENGTH_AS_NUM_ITEMS': not has_length and has_num_items,
          'DEFINE_LENGTH_SETTER': not has_length_setter,
        })
    self._members_emitter.Emit(template, E=element_name)

  def SecureOutputType(self, type_name, is_dart_type=False):
    """ Converts the type name to the secure type name for return types.
    """
    if is_dart_type:
      dart_name = type_name
    else:
      dart_name = self._DartType(type_name)
    # We only need to secure Window.  Only local History and Location are
    # returned in generated code.
    assert(dart_name != 'HistoryBase' and dart_name != 'LocationBase')
    if dart_name == 'Window':
      return _secure_base_types[dart_name]
    return dart_name

  def SecureBaseName(self, type_name):
    if type_name in _secure_base_types:
      return _secure_base_types[type_name]

  def _TransitiveSecondaryParents(self, interface):
    """Returns a list of all non-primary parents.

    The list contains the interface objects for interfaces defined in the
    database, and the name for undefined interfaces.
    """
    def walk(parents):
      for parent in parents:
        parent_name = parent.type.id
        if parent_name == 'EventTarget':
          # Currently EventTarget is implemented as a mixin, not a proper
          # super interface---ignore its members.
          continue
        if IsDartCollectionType(parent_name):
          result.append(parent_name)
          continue
        if self._database.HasInterface(parent_name):
          parent_interface = self._database.GetInterface(parent_name)
          result.append(parent_interface)
          walk(parent_interface.parents)

    result = []
    if interface.parents:
      parent = interface.parents[0]
      if IsPureInterface(parent.type.id):
        walk(interface.parents)
      else:
        walk(interface.parents[1:])
    return result

  def _DartType(self, type_name):
    return self._type_registry.DartType(type_name)
