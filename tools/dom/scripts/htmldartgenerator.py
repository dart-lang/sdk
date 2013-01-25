#!/usr/bin/python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""This module provides shared functionality for the system to generate
dart:html APIs from the IDL database."""

from generator import AnalyzeOperation, ConstantOutputOrder, \
    DartDomNameOfAttribute, FindMatchingAttribute, IsDartCollectionType, \
    IsPureInterface, TypeOrNothing

# Types that are accessible cross-frame in a limited fashion.
# In these cases, the base type (e.g., WindowBase) provides restricted access
# while the subtype (e.g., Window) provides full access to the
# corresponding objects if there are from the same frame.
_secure_base_types = {
  'Window': 'WindowBase',
  'Location': 'LocationBase',
  'History': 'HistoryBase',
}


class HtmlDartGenerator(object):
  def __init__(self, interface, options):
    self._database = options.database
    self._interface = interface
    self._type_registry = options.type_registry
    self._interface_type_info = self._type_registry.TypeInfo(self._interface.id)
    self._renamer = options.renamer

  def EmitSupportCheck(self):
    if self.HasSupportCheck():
      support_check = self.GetSupportCheck()
      self._members_emitter.Emit('\n'
          '  /// Checks if this type is supported on the current platform.\n'
          '  static bool get supported => $SUPPORT_CHECK;\n',
          SUPPORT_CHECK=support_check)

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

    # Group overloaded operations by id.
    operationsById = {}
    for operation in interface.operations:
      if operation.id not in operationsById:
        operationsById[operation.id] = []
      operationsById[operation.id].append(operation)

    # Generate operations.
    for id in sorted(operationsById.keys()):
      operations = operationsById[id]
      info = AnalyzeOperation(interface, operations)
      self.AddOperation(info, declare_only)

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

      # Group overloaded operations by id.
      operationsById = {}
      for operation in parent_interface.operations:
        if operation.id not in operationsById:
          operationsById[operation.id] = []
        operationsById[operation.id].append(operation)

      # Generate operations.
      for id in sorted(operationsById.keys()):
        if not any(op.id == id for op in interface.operations):
          operations = operationsById[id]
          info = AnalyzeOperation(interface, operations)
          self.SecondaryContext(parent_interface)
          self.AddOperation(info)

  def AddConstant(self, constant):
    const_name = self._renamer.RenameMember(
        self._interface.id, constant, constant.id, 'get:', dartify_name=False)
    if not const_name:
      return
    type = TypeOrNothing(self._DartType(constant.type.id), constant.type.id)
    self._members_emitter.Emit('\n  static const $TYPE$NAME = $VALUE;\n',
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
    if not attr_name or self._IsPrivate(attr_name):
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

  def _GenerateDispatcherBody(self,
      operations,
      parameter_names,
      declaration,
      generate_call,
      is_optional,
      can_omit_type_check=lambda type, pos: False):

    body_emitter = self._members_emitter.Emit(
        '\n'
        '  $DECLARATION {\n'
        '$!BODY'
        '  }\n',
        DECLARATION=declaration)

    version = [0]
    def GenerateCall(operation, argument_count, checks):
      if checks:
        (stmts_emitter, call_emitter) = body_emitter.Emit(
            '    if ($CHECKS) {\n$!STMTS$!CALL    }\n',
            INDENT='      ',
            CHECKS=' && '.join(checks))
      else:
        (stmts_emitter, call_emitter) = body_emitter.Emit(
            '$!STMTS$!CALL',
            INDENT='    ');

      if operation.type.id == 'void':
        call_emitter = call_emitter.Emit('$(INDENT)$!CALL;\n$(INDENT)return;\n')
      else:
        call_emitter = call_emitter.Emit('$(INDENT)return $!CALL;\n')

      version[0] += 1
      generate_call(
          stmts_emitter, call_emitter, version[0], operation, argument_count)

    def GenerateChecksAndCall(operation, argument_count):
      checks = []
      for i in range(0, argument_count):
        argument = operation.arguments[i]
        parameter_name = parameter_names[i]
        test_type = self._DartType(argument.type.id)
        if test_type in ['dynamic', 'Object']:
          checks.append('?%s' % parameter_name)
        elif not can_omit_type_check(test_type, i):
          checks.append('(%s is %s || %s == null)' % (
              parameter_name, test_type, parameter_name))
      # There can be multiple presence checks.  We need them all since a later
      # optional argument could have been passed by name, leaving 'holes'.
      checks.extend(['!?%s' % name for name in parameter_names[argument_count:]])

      GenerateCall(operation, argument_count, checks)

    # TODO: Optimize the dispatch to avoid repeated checks.
    if len(operations) > 1:
      for operation in operations:
        for position, argument in enumerate(operation.arguments):
          if is_optional(operation, argument):
            GenerateChecksAndCall(operation, position)
        GenerateChecksAndCall(operation, len(operation.arguments))
      body_emitter.Emit(
          '    throw new ArgumentError("Incorrect number or type of arguments");'
          '\n');
    else:
      operation = operations[0]
      argument_count = len(operation.arguments)
      for position, argument in list(enumerate(operation.arguments))[::-1]:
        if is_optional(operation, argument):
          check = '?%s' % parameter_names[position]
          # argument_count instead of position + 1 is used here to cover one
          # complicated case with the effectively optional argument in the middle.
          # Consider foo(x, [Optional] y, [Optional=DefaultIsNullString] z)
          # (as of now it's modelled after HTMLMediaElement.webkitAddKey).
          # y is optional in WebCore, while z is not.
          # In this case, if y was actually passed, we'd like to emit foo(x, y, z) invocation,
          # not foo(x, y).
          GenerateCall(operation, argument_count, [check])
          argument_count = position
      GenerateCall(operation, argument_count, [])

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
          '  factory $CTOR.fromBuffer(ArrayBuffer buffer, '
              '[int byteOffset, int length]) => \n'
          '    $FACTORY.create$(CTOR)_fromBuffer(buffer, byteOffset, length);\n',
        CTOR=self._interface.id,
        TYPE=self._DartType(typed_array_type),
        FACTORY=factory_name)

  def _AddConstructor(self,
      constructor_info, factory_name, factory_constructor_name):
    self._members_emitter.Emit('\n  @DocsEditable');

    if not factory_constructor_name:
      factory_constructor_name = '_create'
      factory_parameters = constructor_info.ParametersAsArgumentList()
      has_factory_provider = True
    else:
      factory_parameters = ', '.join(constructor_info.factory_parameters)
      has_factory_provider = False

    has_optional = any(param_info.is_optional
        for param_info in constructor_info.param_infos)

    if not has_optional:
      self._members_emitter.Emit(
          '\n'
          '  factory $CTOR($PARAMS) => '
          '$FACTORY.$CTOR_FACTORY_NAME($FACTORY_PARAMS);\n',
          CTOR=constructor_info._ConstructorFullName(self._DartType),
          PARAMS=constructor_info.ParametersDeclaration(self._DartType),
          FACTORY=factory_name,
          CTOR_FACTORY_NAME=factory_constructor_name,
          FACTORY_PARAMS=factory_parameters)
    else:
      if has_factory_provider:
        dispatcher_emitter = self._members_emitter.Emit(
            '\n'
            '  factory $CTOR($PARAMS) {\n'
            '$!DISPATCHER'
            '    return $FACTORY._create($FACTORY_PARAMS);\n'
            '  }\n',
            CTOR=constructor_info._ConstructorFullName(self._DartType),
            PARAMS=constructor_info.ParametersDeclaration(self._DartType),
            FACTORY=factory_name,
            FACTORY_PARAMS=constructor_info.ParametersAsArgumentList())

        for index, param_info in enumerate(constructor_info.param_infos):
          if param_info.is_optional:
            dispatcher_emitter.Emit(
              '    if (!?$OPT_PARAM_NAME) {\n'
              '      return $FACTORY._create($FACTORY_PARAMS);\n'
              '    }\n',
              OPT_PARAM_NAME=param_info.name,
              FACTORY=factory_name,
              FACTORY_PARAMS=constructor_info.ParametersAsArgumentList(index))
      else:
        inits = self._members_emitter.Emit(
            '\n'
            '  factory $CONSTRUCTOR($PARAMS) {\n'
            '    var e = $FACTORY.$CTOR_FACTORY_NAME($FACTORY_PARAMS);\n'
            '$!INITS'
            '    return e;\n'
            '  }\n',
            CONSTRUCTOR=constructor_info._ConstructorFullName(self._DartType),
            FACTORY=factory_name,
            CTOR_FACTORY_NAME=factory_constructor_name,
            PARAMS=constructor_info.ParametersDeclaration(self._DartType),
            FACTORY_PARAMS=factory_parameters)

        for index, param_info in enumerate(constructor_info.param_infos):
          if param_info.is_optional:
            inits.Emit('    if ($E != null) e.$E = $E;\n', E=param_info.name)

    if not constructor_info.pure_dart_constructor:
      self.EmitStaticFactory(constructor_info)

  def EmitHelpers(self, base_class):
    pass

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
    has_contains = any(op.id == 'contains' for op in self._interface.operations)
    has_clear = any(op.id == 'clear' for op in self._interface.operations)
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
          'DEFINE_CONTAINS': not has_contains,
          'DEFINE_CLEAR': not has_clear,
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

  def _IsPrivate(self, name):
    return name.startswith('_')
