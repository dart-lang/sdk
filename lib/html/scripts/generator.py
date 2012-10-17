#!/usr/bin/python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""This module provides shared functionality for systems to generate
Dart APIs from the IDL database."""

import copy
import re
from htmlrenamer import html_interface_renames

_pure_interfaces = set([
    # TODO(sra): DOMStringMap should be a class implementing Map<String,String>.
    'DOMStringMap',
    'ElementTimeControl',
    'ElementTraversal',
    'EventListener',
    'MediaQueryListListener',
    'NodeSelector',
    'SVGExternalResourcesRequired',
    'SVGFilterPrimitiveStandardAttributes',
    'SVGFitToViewBox',
    'SVGLangSpace',
    'SVGLocatable',
    'SVGStylable',
    'SVGTests',
    'SVGTransformable',
    'SVGURIReference',
    'SVGZoomAndPan',
    'TimeoutHandler'])

def IsPureInterface(interface_name):
  return interface_name in _pure_interfaces

#
# Renames for attributes that have names that are not legal Dart names.
#
_dart_attribute_renames = {
    'default': 'defaultValue',
    'final': 'finalValue',
}

#
# Interface version of the DOM needs to delegate typed array constructors to a
# factory provider.
#
interface_factories = {
    'Float32Array': '_TypedArrayFactoryProvider',
    'Float64Array': '_TypedArrayFactoryProvider',
    'Int8Array': '_TypedArrayFactoryProvider',
    'Int16Array': '_TypedArrayFactoryProvider',
    'Int32Array': '_TypedArrayFactoryProvider',
    'Uint8Array': '_TypedArrayFactoryProvider',
    'Uint16Array': '_TypedArrayFactoryProvider',
    'Uint32Array': '_TypedArrayFactoryProvider',
    'Uint8ClampedArray': '_TypedArrayFactoryProvider',
}

#
# Custom native specs for the dart2js dom.
#
_dart2js_dom_custom_native_specs = {
    # Decorate the singleton Console object, if present (workers do not have a
    # console).
    'Console': "=(typeof console == 'undefined' ? {} : console)",

    # DOMWindow aliased with global scope.
    'DOMWindow': '@*DOMWindow',
}

def IsRegisteredType(type_name):
  return type_name in _idl_type_registry

def ListImplementationInfo(interface, database):
  """Returns a tuple (elment_type, requires_indexer).
  If interface do not have to implement List, element_type is None.
  Otherwise element_type is list element type and requires_indexer
  is true iff this interface implementation must have indexer and
  false otherwise.  False means that interface implementation
  inherits indexer and may just reuse it."""
  element_type = MaybeListElementType(interface)
  if element_type:
    return (element_type, True)

  for parent in interface.parents:
    if database.HasInterface(parent.type.id):
      parent_interface = database.GetInterface(parent.type.id)
      (element_type, _) = ListImplementationInfo(parent_interface, database)
      if element_type:
        return (element_type, False)

  return (None, None)


def MaybeListElementType(interface):
  """Returns the List element type T, or None in interface does not implement
  List<T>.
  """
  for parent in interface.parents:
    match = re.match(r'sequence<(\w*)>$', parent.type.id)
    if match:
      return match.group(1)
  return None

def MaybeTypedArrayElementType(interface):
  """Returns the typed array element type, or None in interface is not a
  TypedArray.
  """
  # Typed arrays implement ArrayBufferView and List<T>.
  for parent in interface.parents:
    if parent.type.id == 'ArrayBufferView':
      return MaybeListElementType(interface)
  return None

def MaybeTypedArrayElementTypeInHierarchy(interface, database):
  """Returns the typed array element type, or None in interface is not a
  TypedArray.  Checks the whole parent hierarchy.
  """
  element_type = MaybeTypedArrayElementType(interface)
  if element_type:
    return element_type
  for parent in interface.parents:
    if database.HasInterface(parent.type.id):
      parent_interface = database.GetInterface(parent.type.id)
      element_type = MaybeTypedArrayElementType(parent_interface)
      if element_type:
        return element_type

  return None

def MakeNativeSpec(javascript_binding_name):
  if javascript_binding_name in _dart2js_dom_custom_native_specs:
    return _dart2js_dom_custom_native_specs[javascript_binding_name]
  else:
    # Make the class 'hidden' so it is dynamically patched at runtime.  This
    # is useful for browser compat.
    return '*' + javascript_binding_name


def MatchSourceFilter(thing):
  return 'WebKit' in thing.annotations or 'Dart' in thing.annotations


class ParamInfo(object):
  """Holder for various information about a parameter of a Dart operation.

  Attributes:
    name: Name of parameter.
    type_id: Original type id.  None for merged types.
    is_optional: Parameter optionality.
  """
  def __init__(self, name, type_id, is_optional):
    self.name = name
    self.type_id = type_id
    self.is_optional = is_optional

  def Copy(self):
    return ParamInfo(self.name, self.type_id, self.is_optional)

  def __repr__(self):
    content = 'name = %s, type_id = %s, is_optional = %s' % (
        self.name, self.type_id, self.is_optional)
    return '<ParamInfo(%s)>' % content


# Given a list of overloaded arguments, render dart arguments.
def _BuildArguments(args, interface, constructor=False):
  def IsOptional(argument):
    if 'Callback' in argument.ext_attrs:
      # Callbacks with 'Optional=XXX' are treated as optional arguments.
      return 'Optional' in argument.ext_attrs
    if constructor:
      # FIXME: Constructors with 'Optional=XXX' shouldn't be treated as
      # optional arguments.
      return 'Optional' in argument.ext_attrs
    return False

  # Given a list of overloaded arguments, choose a suitable name.
  def OverloadedName(args):
    return '_OR_'.join(sorted(set(arg.id for arg in args)))

  def DartType(idl_type_name):
   if idl_type_name in _idl_type_registry:
     return _idl_type_registry[idl_type_name].dart_type or idl_type_name
   return idl_type_name

  # Given a list of overloaded arguments, choose a suitable type.
  def OverloadedType(args):
    type_ids = sorted(set(arg.type.id for arg in args))
    if len(set(DartType(arg.type.id) for arg in args)) == 1:
      return type_ids[0]
    else:
      return None

  result = []

  is_optional = False
  for arg_tuple in map(lambda *x: x, *args):
    is_optional = is_optional or any(arg is None or IsOptional(arg) for arg in arg_tuple)

    filtered = filter(None, arg_tuple)
    type_id = OverloadedType(filtered)
    name = OverloadedName(filtered)
    result.append(ParamInfo(name, type_id, is_optional))

  return result

def IsOptional(argument):
  return ('Optional' in argument.ext_attrs and
          argument.ext_attrs['Optional'] == None)

def AnalyzeOperation(interface, operations):
  """Makes operation calling convention decision for a set of overloads.

  Returns: An OperationInfo object.
  """

  # split operations with optional args into multiple operations
  split_operations = []
  for operation in operations:
    for i in range(0, len(operation.arguments)):
      if IsOptional(operation.arguments[i]):
        new_operation = copy.deepcopy(operation)
        new_operation.arguments = new_operation.arguments[:i]
        split_operations.append(new_operation)
    split_operations.append(operation)

  # Zip together arguments from each overload by position, then convert
  # to a dart argument.
  info = OperationInfo()
  info.operations = operations
  info.overloads = split_operations
  info.declared_name = operations[0].id
  info.name = operations[0].ext_attrs.get('DartName', info.declared_name)
  info.constructor_name = None
  info.js_name = info.declared_name
  info.type_name = operations[0].type.id   # TODO: widen.
  info.param_infos = _BuildArguments([op.arguments for op in split_operations], interface)
  return info


def AnalyzeConstructor(interface):
  """Returns an OperationInfo object for the constructor.

  Returns None if the interface has no Constructor.
  """
  if 'Constructor' in interface.ext_attrs:
    name = None
    func_value = interface.ext_attrs.get('Constructor')
    if not func_value:
      args = []
      idl_args = []
  elif 'NamedConstructor' in interface.ext_attrs:
    func_value = interface.ext_attrs.get('NamedConstructor')
    name = func_value.id
  else:
    return None

  if func_value:
    idl_args = func_value.arguments
    args =_BuildArguments([idl_args], interface, True)

  info = OperationInfo()
  info.overloads = None
  info.idl_args = idl_args
  info.declared_name = name
  info.name = name
  info.constructor_name = None
  info.js_name = name
  info.type_name = interface.id
  info.param_infos = args
  return info

def IsDartListType(type):
  return type == 'List' or type.startswith('sequence<')

def IsDartCollectionType(type):
  return IsDartListType(type)

def FindMatchingAttribute(interface, attr1):
  matches = [attr2 for attr2 in interface.attributes
             if attr1.id == attr2.id]
  if matches:
    assert len(matches) == 1
    return matches[0]
  return None


def DartDomNameOfAttribute(attr):
  """Returns the Dart name for an IDLAttribute.

  attr.id is the 'native' or JavaScript name.

  To ensure uniformity, work with the true IDL name until as late a possible,
  e.g. translate to the Dart name when generating Dart code.
  """
  name = attr.id
  name = _dart_attribute_renames.get(name, name)
  name = attr.ext_attrs.get('DartName', None) or name
  return name


def TypeOrNothing(dart_type, comment=None):
  """Returns string for declaring something with |dart_type| in a context
  where a type may be omitted.
  The string is empty or has a trailing space.
  """
  if dart_type == 'Dynamic':
    if comment:
      return '/*%s*/ ' % comment   # Just a comment foo(/*T*/ x)
    else:
      return ''                    # foo(x) looks nicer than foo(Dynamic x)
  else:
    return dart_type + ' '


def TypeOrVar(dart_type, comment=None):
  """Returns string for declaring something with |dart_type| in a context
  where if a type is omitted, 'var' must be used instead."""
  if dart_type == 'Dynamic':
    if comment:
      return 'var /*%s*/' % comment   # e.g.  var /*T*/ x;
    else:
      return 'var'                    # e.g.  var x;
  else:
    return dart_type


class OperationInfo(object):
  """Holder for various derived information from a set of overloaded operations.

  Attributes:
    overloads: A list of IDL operation overloads with the same name.
    name: A string, the simple name of the operation.
    constructor_name: A string, the name of the constructor iff the constructor
       is named, e.g. 'fromList' in  Int8Array.fromList(list).
    type_name: A string, the name of the return type of the operation.
    param_infos: A list of ParamInfo.
  """

  def ParametersInterfaceDeclaration(self, rename_type):
    """Returns a formatted string declaring the parameters for the interface."""
    return self._FormatParams(self.param_infos, rename_type, True)

  def ParametersImplementationDeclaration(self, rename_type):
    """Returns a formatted string declaring the parameters for the
    implementation.

    Args:
      rename_type: A function that allows the types to be renamed.
        The function is applied to the parameter's dart_type.
    """
    return self._FormatParams(self.param_infos, rename_type, False)

  def ParametersAsArgumentList(self, parameter_count = None):
    """Returns a string of the parameter names suitable for passing the
    parameters as arguments.
    """
    if parameter_count is None:
      parameter_count = len(self.param_infos)
    return ', '.join(map(
        lambda param_info: param_info.name,
        self.param_infos[:parameter_count]))

  def _FormatParams(self, params, rename_type, provide_comments):
    def FormatParam(param):
      dart_type = rename_type(param.type_id) if param.type_id else 'Dynamic'
      type = TypeOrNothing(dart_type, param.type_id if provide_comments else None)
      return '%s%s' % (type, param.name)

    required = []
    optional = []
    for param_info in params:
      if param_info.is_optional:
        optional.append(param_info)
      else:
        if optional:
          raise Exception('Optional parameters cannot precede required ones: '
                          + str(params))
        required.append(param_info)
    argtexts = map(FormatParam, required)
    if optional:
      argtexts.append('[' + ', '.join(map(FormatParam, optional)) + ']')
    return ', '.join(argtexts)

  def IsStatic(self):
    is_static = self.overloads[0].is_static
    assert any([is_static == o.is_static for o in self.overloads])
    return is_static

  def _ConstructorFullName(self, rename_type):
    if self.constructor_name:
      return rename_type(self.type_name) + '.' + self.constructor_name
    else:
      return rename_type(self.type_name)

  def ConstructorFactoryName(self, rename_type):
    return 'create' + self._ConstructorFullName(rename_type).replace('.', '_')

  def GenerateFactoryInvocation(self, rename_type, emitter, factory_provider):
    has_optional = any(param_info.is_optional
        for param_info in self.param_infos)

    factory_name = self.ConstructorFactoryName(rename_type)
    if not has_optional:
      emitter.Emit(
          '\n'
          '  factory $CTOR($PARAMS) => '
          '$FACTORY.$CTOR_FACTORY_NAME($FACTORY_PARAMS);\n',
          CTOR=self._ConstructorFullName(rename_type),
          PARAMS=self.ParametersInterfaceDeclaration(rename_type),
          FACTORY=factory_provider,
          CTOR_FACTORY_NAME=factory_name,
          FACTORY_PARAMS=self.ParametersAsArgumentList())
      return

    dispatcher_emitter = emitter.Emit(
        '\n'
        '  factory $CTOR($PARAMS) {\n'
        '$!DISPATCHER'
        '    return $FACTORY.$CTOR_FACTORY_NAME($FACTORY_PARAMS);\n'
        '  }\n',
        CTOR=self._ConstructorFullName(rename_type),
        PARAMS=self.ParametersInterfaceDeclaration(rename_type),
        FACTORY=factory_provider,
        CTOR_FACTORY_NAME=factory_name,
        FACTORY_PARAMS=self.ParametersAsArgumentList())

    # If we have optional parameters, check to see if they are set
    # and call the appropriate factory method.
    def EmitOptionalParameterInvocation(index):
      dispatcher_emitter.Emit(
        '    if (!?$OPT_PARAM_NAME) {\n'
        '      return $FACTORY.$CTOR_FACTORY_NAME($FACTORY_PARAMS);\n'
        '    }\n',
        OPT_PARAM_NAME=self.param_infos[index].name,
        FACTORY=factory_provider,
        CTOR_FACTORY_NAME=factory_name,
        FACTORY_PARAMS=self.ParametersAsArgumentList(index))

    for index, param_info in enumerate(self.param_infos):
      if param_info.is_optional:
        EmitOptionalParameterInvocation(index)


  def CopyAndWidenDefaultParameters(self):
    """Returns equivalent OperationInfo, but default parameters are Dynamic."""
    info = copy.copy(self)
    info.param_infos = [param.Copy() for param in self.param_infos]
    for param in info.param_infos:
      if param.is_optional:
        param.type_id = None
    return info


def ConstantOutputOrder(a, b):
  """Canonical output ordering for constants."""
  if a.id < b.id: return -1
  if a.id > b.id: return 1
  return 0


def _FormatNameList(names):
  """Returns JavaScript array literal expression with one name per line."""
  #names = sorted(names)
  if len(names) <= 1:
    expression_string = str(names)  # e.g.  ['length']
  else:
    expression_string = ',\n   '.join(str(names).split(','))
    expression_string = expression_string.replace('[', '[\n    ')
  return expression_string


def IndentText(text, indent):
  """Format lines of text with indent."""
  def FormatLine(line):
    if line.strip():
      return '%s%s\n' % (indent, line)
    else:
      return '\n'
  return ''.join(FormatLine(line) for line in text.split('\n'))

# Given a sorted sequence of type identifiers, return an appropriate type
# name
def TypeName(type_ids, interface):
  # Dynamically type this field for now.
  return 'Dynamic'

def ImplementationClassNameForInterfaceName(interface_name):
  return '_%sImpl' % interface_name

# ------------------------------------------------------------------------------

class Conversion(object):
  """Represents a way of converting between types."""
  def __init__(self, name, input_type, output_type):
    # input_type is the type of the API input (and the argument type of the
    # conversion function)
    # output_type is the type of the API output (and the result type of the
    # conversion function)
    self.function_name = name
    self.input_type = input_type
    self.output_type = output_type

#  "TYPE DIRECTION INTERFACE.MEMBER" -> conversion
#     Specific member of interface
#  "TYPE DIRECTION INTERFACE.*" -> conversion
#     All members of interface getting (setting) with type.
#  "TYPE DIRECTION" -> conversion
#     All getters (setters) of type.
#
# where DIRECTION is 'get' for getters and operation return values, 'set' for
# setters and operation arguments.  INTERFACE and MEMBER are the idl names.
#

_serialize_SSV = Conversion('_convertDartToNative_SerializedScriptValue',
                           'Dynamic', 'Dynamic')

dart2js_conversions = {
    # Wrap non-local Windows.  We need to check EventTarget (the base type)
    # as well.  Note, there are no functions that take a non-local Window
    # as a parameter / setter.
    'DOMWindow get':
      Conversion('_convertNativeToDart_Window', 'Window', 'Window'),
    'EventTarget get':
      Conversion('_convertNativeToDart_EventTarget', 'EventTarget',
                 'EventTarget'),
    'EventTarget set':
      Conversion('_convertDartToNative_EventTarget', 'EventTarget',
                 'EventTarget'),

    'IDBKey get':
      Conversion('_convertNativeToDart_IDBKey', 'Dynamic', 'Dynamic'),
    'IDBKey set':
      Conversion('_convertDartToNative_IDBKey', 'Dynamic', 'Dynamic'),

    'ImageData get':
      Conversion('_convertNativeToDart_ImageData', 'Dynamic', 'ImageData'),
    'ImageData set':
      Conversion('_convertDartToNative_ImageData', 'ImageData', 'Dynamic'),

    'Dictionary get':
      Conversion('_convertNativeToDart_Dictionary', 'Dynamic', 'Map'),
    'Dictionary set':
      Conversion('_convertDartToNative_Dictionary', 'Map', 'Dynamic'),

    'DOMString[] set':
      Conversion('_convertDartToNative_StringArray', 'List<String>', 'List'),

    'any set IDBObjectStore.add': _serialize_SSV,
    'any set IDBObjectStore.put': _serialize_SSV,
    'any set IDBCursor.update': _serialize_SSV,

    # postMessage
    'any set DedicatedWorkerContext.postMessage': _serialize_SSV,
    'any set MessagePort.postMessage': _serialize_SSV,
    'SerializedScriptValue set DOMWindow.postMessage': _serialize_SSV,
    'SerializedScriptValue set Worker.postMessage': _serialize_SSV,

    # receiving message via MessageEvent
    'DOMObject get MessageEvent.data':
      Conversion('_convertNativeToDart_SerializedScriptValue',
                 'Dynamic', 'Dynamic'),


    # IDBAny is problematic.  Some uses are just a union of other IDB types,
    # which need no conversion..  Others include data values which require
    # serialized script value processing.
    'IDBAny get IDBCursorWithValue.value':
      Conversion('_convertNativeToDart_IDBAny', 'Dynamic', 'Dynamic'),

    # This is problematic.  The result property of IDBRequest is used for
    # all requests.  Read requests like IDBDataStore.getObject need
    # conversion, but other requests like opening a database return
    # something that does not need conversion.
    'IDBAny get IDBRequest.result':
      Conversion('_convertNativeToDart_IDBAny', 'Dynamic', 'Dynamic'),

    # "source: On getting, returns the IDBObjectStore or IDBIndex that the
    # cursor is iterating. ...".  So we should not try to convert it.
    'IDBAny get IDBCursor.source': None,

    # Should be either a DOMString, an Array of DOMStrings or null.
    'IDBAny get IDBObjectStore.keyPath': None,
}

def FindConversion(idl_type, direction, interface, member):
  table = dart2js_conversions
  return (table.get('%s %s %s.%s' % (idl_type, direction, interface, member)) or
          table.get('%s %s %s.*' % (idl_type, direction, interface)) or
          table.get('%s %s' % (idl_type, direction)))
  return None

# ------------------------------------------------------------------------------

class IDLTypeInfo(object):
  def __init__(self, idl_type, data):
    self._idl_type = idl_type
    self._data = data

  def idl_type(self):
    return self._idl_type

  def dart_type(self):
    return self._data.dart_type or self._idl_type

  def narrow_dart_type(self):
    return self.dart_type()

  def interface_name(self):
    raise NotImplementedError()

  def implementation_name(self):
    raise NotImplementedError()

  def has_generated_interface(self):
    raise NotImplementedError()

  def merged_interface(self):
    return None

  def merged_into(self):
    return None

  def native_type(self):
    return self._data.native_type or self._idl_type

  def bindings_class(self):
    return 'Dart%s' % self.idl_type()

  def vector_to_dart_template_parameter(self):
    return self.bindings_class()

  def requires_v8_scope(self):
    return self._data.requires_v8_scope

  def to_native_info(self, idl_node, interface_name):
    cls = self.bindings_class()

    if 'Callback' in idl_node.ext_attrs:
      return '%s', 'RefPtr<%s>' % self.native_type(), cls, 'create'

    if self.custom_to_native():
      type = 'RefPtr<%s>' % self.native_type()
      argument_expression_template = '%s.get()'
    else:
      type = '%s*' % self.native_type()
      if isinstance(self, SVGTearOffIDLTypeInfo) and not interface_name.endswith('List'):
        argument_expression_template = '%s->propertyReference()'
      else:
        argument_expression_template = '%s'
    return argument_expression_template, type, cls, 'toNative'

  def pass_native_by_ref(self): return False

  def custom_to_native(self):
    return self._data.custom_to_native

  def parameter_type(self):
    return '%s*' % self.native_type()

  def webcore_includes(self):
    WTF_INCLUDES = [
        'ArrayBuffer',
        'ArrayBufferView',
        'Float32Array',
        'Float64Array',
        'Int8Array',
        'Int16Array',
        'Int32Array',
        'Uint8Array',
        'Uint16Array',
        'Uint32Array',
        'Uint8ClampedArray',
    ]

    if self._idl_type in WTF_INCLUDES:
      return ['<wtf/%s.h>' % self.native_type()]

    if not self._idl_type.startswith('SVG'):
      return ['"%s.h"' % self.native_type()]

    if self._idl_type in ['SVGNumber', 'SVGPoint']:
      return ['"SVGPropertyTearOff.h"']
    if self._idl_type.startswith('SVGPathSeg'):
      include = self._idl_type.replace('Abs', '').replace('Rel', '')
    else:
      include = self._idl_type
    return ['"%s.h"' % include] + _svg_supplemental_includes

  def receiver(self):
    return 'receiver->'

  def conversion_includes(self):
    includes = [self._idl_type] + (self._data.conversion_includes or [])
    return ['"Dart%s.h"' % include for include in includes]

  def to_dart_conversion(self, value, interface_name=None, attributes=None):
    return 'Dart%s::toDart(%s)' % (self._idl_type, value)

  def custom_to_dart(self):
    return self._data.custom_to_dart


class InterfaceIDLTypeInfo(IDLTypeInfo):
  def __init__(self, idl_type, data, dart_interface_name):
    super(InterfaceIDLTypeInfo, self).__init__(idl_type, data)
    self._dart_interface_name = dart_interface_name

  def dart_type(self):
    return self._data.dart_type or self._dart_interface_name

  def narrow_dart_type(self):
    # TODO(podivilov): only primitive and collection types should override
    # dart_type.
    if self._data.dart_type != None:
      return self.dart_type()
    if IsPureInterface(self.idl_type()):
      return self.idl_type()
    return self.implementation_name()

  def interface_name(self):
    return self._dart_interface_name

  def implementation_name(self):
    return ImplementationClassNameForInterfaceName(self._dart_interface_name)

  def has_generated_interface(self):
    return True

  def merged_interface(self):
    # All constants, attributes, and operations of merged interface should be
    # added to this interface. Merged idl interface does not have corresponding
    # Dart generated interface, and all references to merged idl interface
    # (e.g. parameter types, return types, parent interfaces) should be replaced
    # with this interface. There are two important restrictions:
    # 1) Merged and target interfaces shouldn't have common members, otherwise
    # there would be duplicated declarations in generated Dart code.
    # 2) Merged interface should be direct child of target interface, so the
    # children of merged interface are not affected by the merge.
    # As a consequence, target interface implementation and its direct children
    # interface implementations should implement merged attribute accessors and
    # operations. For example, SVGElement and Element implementation classes
    # should implement HTMLElement.insertAdjacentElement(),
    # HTMLElement.innerHTML, etc.
    return self._data.merged_interface

  def merged_into(self):
    return self._data.merged_into


class CallbackIDLTypeInfo(IDLTypeInfo):
  def __init__(self, idl_type, data):
    super(CallbackIDLTypeInfo, self).__init__(idl_type, data)


# Type info for DOM types that are converted to dart lists and therefore whose
# actual interface generation should be suppressed. For type information, we
# still generate the implementations though, so these types should not be
# suppressed entirely.
class ListLikeIDLTypeInfo(IDLTypeInfo):
  def __init__(self, idl_type, data, item_info):
    super(ListLikeIDLTypeInfo, self).__init__(idl_type, data)
    self._item_info = item_info

  def dart_type(self):
    return 'List<%s>' % self._item_info.dart_type()

  def narrow_dart_type(self):
    if self.has_generated_interface():
      return self.dart_type()
    return ImplementationClassNameForInterfaceName(self.idl_type())

  def interface_name(self):
    if self.has_generated_interface():
      return self.idl_type()
    return self.dart_type()

  def implementation_name(self):
    return ImplementationClassNameForInterfaceName(self.idl_type())

  def has_generated_interface(self):
    # Don't generate interfaces for list-like types.
    # TODO(podivilov): why NodeList is special? Is it indeed a list-like type
    # or should just implement sequence<Node>?
    return self.idl_type() == 'NodeList'


class SequenceIDLTypeInfo(IDLTypeInfo):
  def __init__(self, idl_type, data, item_info):
    super(SequenceIDLTypeInfo, self).__init__(idl_type, data)
    self._item_info = item_info

  def dart_type(self):
    return 'List<%s>' % self._item_info.dart_type()

  def interface_name(self):
    return self.dart_type()

  def implementation_name(self):
    return self.dart_type()

  def vector_to_dart_template_parameter(self):
    raise Exception('sequences of sequences are not supported yet')

  def to_native_info(self, idl_node, interface_name):
    item_native_type = self._item_info.vector_to_dart_template_parameter()
    return '%s', 'Vector<%s>' % item_native_type, 'DartUtilities', 'toNativeVector<%s>' % item_native_type

  def pass_native_by_ref(self): return True

  def to_dart_conversion(self, value, interface_name=None, attributes=None):
    return 'DartDOMWrapper::vectorToDart<%s>(%s)' % (self._item_info.vector_to_dart_template_parameter(), value)

  def conversion_includes(self):
    return self._item_info.conversion_includes()


class DOMStringArrayTypeInfo(SequenceIDLTypeInfo):
  def __init__(self, data, item_info):
    super(DOMStringArrayTypeInfo, self).__init__('DOMString[]', data, item_info)

  def to_native_info(self, idl_node, interface_name):
    return '%s', 'RefPtr<DOMStringList>', 'DartDOMStringList', 'toNative'

  def pass_native_by_ref(self): return False


class PrimitiveIDLTypeInfo(IDLTypeInfo):
  def __init__(self, idl_type, data):
    super(PrimitiveIDLTypeInfo, self).__init__(idl_type, data)

  def vector_to_dart_template_parameter(self):
    # Ugly hack. Usually IDLs floats are treated as C++ doubles, however
    # sequence<float> should map to Vector<float>
    if self.idl_type() == 'float': return 'float'
    return self.native_type()

  def to_native_info(self, idl_node, interface_name):
    type = self.native_type()
    if type == 'SerializedScriptValue':
      type = 'RefPtr<%s>' % type
    if type == 'String':
      type = 'DartStringAdapter'
    return '%s', type, 'DartUtilities', 'dartTo%s' % self._capitalized_native_type()

  def parameter_type(self):
    if self.native_type() == 'String':
      return 'const String&'
    return self.native_type()

  def conversion_includes(self):
    return []

  def to_dart_conversion(self, value, interface_name=None, attributes=None):
    function_name = self._capitalized_native_type()
    function_name = function_name[0].lower() + function_name[1:]
    function_name = 'DartUtilities::%sToDart' % function_name
    if attributes and 'TreatReturnedNullStringAs' in attributes:
      function_name += 'WithNullCheck'
    return '%s(%s)' % (function_name, value)

  def webcore_getter_name(self):
    return self._data.webcore_getter_name

  def webcore_setter_name(self):
    return self._data.webcore_setter_name

  def _capitalized_native_type(self):
    return re.sub(r'(^| )([a-z])', lambda x: x.group(2).upper(), self.native_type())


class SVGTearOffIDLTypeInfo(InterfaceIDLTypeInfo):
  def __init__(self, idl_type, data):
    super(SVGTearOffIDLTypeInfo, self).__init__(idl_type, data, idl_type)

  def native_type(self):
    if self._data.native_type:
      return self._data.native_type
    tear_off_type = 'SVGPropertyTearOff'
    if self._idl_type.endswith('List'):
      tear_off_type = 'SVGListPropertyTearOff'
    return '%s<%s>' % (tear_off_type, self._idl_type)

  def receiver(self):
    if self._idl_type.endswith('List'):
      return 'receiver->'
    return 'receiver->propertyReference().'

  def to_dart_conversion(self, value, interface_name, attributes):
    svg_primitive_types = ['SVGAngle', 'SVGLength', 'SVGMatrix',
        'SVGNumber', 'SVGPoint', 'SVGRect', 'SVGTransform']
    conversion_cast = '%s::create(%s)'
    if interface_name.startswith('SVGAnimated'):
      conversion_cast = 'static_cast<%s*>(%s)'
    elif self.idl_type() == 'SVGStringList':
      conversion_cast = '%s::create(receiver, %s)'
    elif interface_name.endswith('List'):
      conversion_cast = 'static_cast<%s*>(%s.get())'
    elif self.idl_type() in svg_primitive_types:
      conversion_cast = '%s::create(%s)'
    else:
      conversion_cast = 'static_cast<%s*>(%s)'
    conversion_cast = conversion_cast % (self.native_type(), value)
    return 'Dart%s::toDart(%s)' % (self._idl_type, conversion_cast)

  def argument_expression(self, name, interface_name):
    return name if interface_name.endswith('List') else '%s->propertyReference()' % name


class TypeData(object):
  def __init__(self, clazz, dart_type=None, native_type=None,
               merged_interface=None, merged_into=None,
               custom_to_dart=None, custom_to_native=None,
               conversion_includes=None,
               webcore_getter_name='getAttribute',
               webcore_setter_name='setAttribute',
               requires_v8_scope=False,
               item_type=None):
    self.clazz = clazz
    self.dart_type = dart_type
    self.native_type = native_type
    self.merged_interface = merged_interface
    self.merged_into = merged_into
    self.custom_to_dart = custom_to_dart
    self.custom_to_native = custom_to_native
    self.conversion_includes = conversion_includes
    self.webcore_getter_name = webcore_getter_name
    self.webcore_setter_name = webcore_setter_name
    self.requires_v8_scope = requires_v8_scope
    self.item_type = item_type


_idl_type_registry = {
    'boolean': TypeData(clazz='Primitive', dart_type='bool', native_type='bool',
                        webcore_getter_name='hasAttribute',
                        webcore_setter_name='setBooleanAttribute'),
    'byte': TypeData(clazz='Primitive', dart_type='int', native_type='int'),
    'octet': TypeData(clazz='Primitive', dart_type='int', native_type='int'),
    'short': TypeData(clazz='Primitive', dart_type='int', native_type='int'),
    'unsigned short': TypeData(clazz='Primitive', dart_type='int',
        native_type='int'),
    'int': TypeData(clazz='Primitive', dart_type='int'),
    'unsigned int': TypeData(clazz='Primitive', dart_type='int',
        native_type='unsigned'),
    'long': TypeData(clazz='Primitive', dart_type='int', native_type='int',
        webcore_getter_name='getIntegralAttribute',
        webcore_setter_name='setIntegralAttribute'),
    'unsigned long': TypeData(clazz='Primitive', dart_type='int',
                              native_type='unsigned',
                              webcore_getter_name='getUnsignedIntegralAttribute',
                              webcore_setter_name='setUnsignedIntegralAttribute'),
    'long long': TypeData(clazz='Primitive', dart_type='int'),
    'unsigned long long': TypeData(clazz='Primitive', dart_type='int'),
    'float': TypeData(clazz='Primitive', dart_type='num', native_type='double'),
    'double': TypeData(clazz='Primitive', dart_type='num'),

    'any': TypeData(clazz='Primitive', dart_type='Object', native_type='ScriptValue', requires_v8_scope=True),
    'Array': TypeData(clazz='Primitive', dart_type='List'),
    'custom': TypeData(clazz='Primitive', dart_type='Dynamic'),
    'Date': TypeData(clazz='Primitive', dart_type='Date', native_type='double'),
    'DOMObject': TypeData(clazz='Primitive', dart_type='Object', native_type='ScriptValue'),
    'DOMString': TypeData(clazz='Primitive', dart_type='String', native_type='String'),
    # TODO(vsm): This won't actually work until we convert the Map to
    # a native JS Map for JS DOM.
    'Dictionary': TypeData(clazz='Primitive', dart_type='Map', requires_v8_scope=True),
    # TODO(sra): Flags is really a dictionary: {create:bool, exclusive:bool}
    # http://dev.w3.org/2009/dap/file-system/file-dir-sys.html#the-flags-interface
    'Flags': TypeData(clazz='Primitive', dart_type='Object'),
    'DOMTimeStamp': TypeData(clazz='Primitive', dart_type='int', native_type='unsigned long long'),
    'object': TypeData(clazz='Primitive', dart_type='Object', native_type='ScriptValue'),
    'ObjectArray': TypeData(clazz='Primitive', dart_type='List'),
    'PositionOptions': TypeData(clazz='Primitive', dart_type='Object'),
    # TODO(sra): Come up with some meaningful name so that where this appears in
    # the documentation, the user is made aware that only a limited subset of
    # serializable types are actually permitted.
    'SerializedScriptValue': TypeData(clazz='Primitive', dart_type='Dynamic'),
    # TODO(sra): Flags is really a dictionary: {create:bool, exclusive:bool}
    # http://dev.w3.org/2009/dap/file-system/file-dir-sys.html#the-flags-interface
    'WebKitFlags': TypeData(clazz='Primitive', dart_type='Object'),

    'sequence': TypeData(clazz='Primitive', dart_type='List'),
    'void': TypeData(clazz='Primitive', dart_type='void'),

    'CSSRule': TypeData(clazz='Interface', conversion_includes=['CSSImportRule']),
    'DOMException': TypeData(clazz='Interface', native_type='DOMCoreException'),
    'DOMStringMap': TypeData(clazz='Interface', dart_type='Map<String, String>'),
    'DOMWindow': TypeData(clazz='Interface', custom_to_dart=True),
    'Document': TypeData(clazz='Interface', merged_interface='HTMLDocument'),
    'Element': TypeData(clazz='Interface', merged_interface='HTMLElement',
        custom_to_dart=True),
    'EventListener': TypeData(clazz='Interface', custom_to_native=True),
    'EventTarget': TypeData(clazz='Interface', custom_to_native=True),
    'HTMLDocument': TypeData(clazz='Interface', merged_into='Document'),
    'HTMLElement': TypeData(clazz='Interface', merged_into='Element',
        custom_to_dart=True),
    'IDBAny': TypeData(clazz='Interface', dart_type='Dynamic', custom_to_native=True),
    'IDBKey': TypeData(clazz='Interface', dart_type='Dynamic', custom_to_native=True),
    'MutationRecordArray': TypeData(clazz='Interface',  # C++ pass by pointer.
        native_type='MutationRecordArray', dart_type='List<MutationRecord>'),
    'StyleSheet': TypeData(clazz='Interface', conversion_includes=['CSSStyleSheet']),
    'SVGElement': TypeData(clazz='Interface', custom_to_dart=True),

    'ClientRectList': TypeData(clazz='ListLike', item_type='ClientRect'),
    'CSSRuleList': TypeData(clazz='ListLike', item_type='CSSRule'),
    'CSSValueList': TypeData(clazz='ListLike', item_type='CSSValue'),
    'DOMStringList': TypeData(clazz='ListLike', item_type='DOMString',
        custom_to_native=True),
    'EntryArray': TypeData(clazz='ListLike', item_type='Entry'),
    'EntryArraySync': TypeData(clazz='ListLike', item_type='EntrySync'),
    'FileList': TypeData(clazz='ListLike', item_type='File'),
    'GamepadList': TypeData(clazz='ListLike', item_type='Gamepad'),
    'MediaStreamList': TypeData(clazz='ListLike', item_type='MediaStream'),
    'NodeList': TypeData(clazz='ListLike', item_type='Node'),
    'SVGElementInstanceList': TypeData(clazz='ListLike',
        item_type='SVGElementInstance'),
    'SpeechInputResultList': TypeData(clazz='ListLike',
        item_type='SpeechInputResult'),
    'SpeechRecognitionResultList': TypeData(clazz='ListLike',
        item_type='SpeechRecognitionResult'),
    'StyleSheetList': TypeData(clazz='ListLike', item_type='StyleSheet'),
    'WebKitAnimationList': TypeData(clazz='ListLike',
        item_type='WebKitAnimation'),

    'SVGAngle': TypeData(clazz='SVGTearOff'),
    'SVGLength': TypeData(clazz='SVGTearOff'),
    'SVGLengthList': TypeData(clazz='SVGTearOff'),
    'SVGMatrix': TypeData(clazz='SVGTearOff'),
    'SVGNumber': TypeData(clazz='SVGTearOff', native_type='SVGPropertyTearOff<float>'),
    'SVGNumberList': TypeData(clazz='SVGTearOff'),
    'SVGPathSegList': TypeData(clazz='SVGTearOff', native_type='SVGPathSegListPropertyTearOff'),
    'SVGPoint': TypeData(clazz='SVGTearOff', native_type='SVGPropertyTearOff<FloatPoint>'),
    'SVGPointList': TypeData(clazz='SVGTearOff'),
    'SVGPreserveAspectRatio': TypeData(clazz='SVGTearOff'),
    'SVGRect': TypeData(clazz='SVGTearOff', native_type='SVGPropertyTearOff<FloatRect>'),
    'SVGStringList': TypeData(clazz='SVGTearOff', native_type='SVGStaticListPropertyTearOff<SVGStringList>'),
    'SVGTransform': TypeData(clazz='SVGTearOff'),
    'SVGTransformList': TypeData(clazz='SVGTearOff', native_type='SVGTransformListPropertyTearOff'),
}

_svg_supplemental_includes = [
    '"SVGAnimatedPropertyTearOff.h"',
    '"SVGAnimatedListPropertyTearOff.h"',
    '"SVGStaticListPropertyTearOff.h"',
    '"SVGAnimatedListPropertyTearOff.h"',
    '"SVGTransformListPropertyTearOff.h"',
    '"SVGPathSegListPropertyTearOff.h"',
]

class TypeRegistry(object):
  def __init__(self, database, renamer=None):
    self._database = database
    self._renamer = renamer
    self._cache = {}

  def TypeInfo(self, type_name):
    if not type_name in self._cache:
      self._cache[type_name] = self._TypeInfo(type_name)
    return self._cache[type_name]

  def DartType(self, type_name):
    return self.TypeInfo(type_name).dart_type()

  def _TypeInfo(self, type_name):
    match = re.match(r'(?:sequence<(\w+)>|(\w+)\[\])$', type_name)
    if match:
      if type_name == 'DOMString[]':
        return DOMStringArrayTypeInfo(TypeData('Sequence'), self.TypeInfo('DOMString'))
      item_info = self.TypeInfo(match.group(1) or match.group(2))
      return SequenceIDLTypeInfo(type_name, TypeData('Sequence'), item_info)

    if not type_name in _idl_type_registry:
      interface = self._database.GetInterface(type_name)
      if 'Callback' in interface.ext_attrs:
        return CallbackIDLTypeInfo(type_name, TypeData('Callback'))
      return InterfaceIDLTypeInfo(
          type_name,
          TypeData('Interface'),
          self._renamer.RenameInterface(interface))

    type_data = _idl_type_registry.get(type_name)

    if type_data.clazz == 'Interface':
      if self._database.HasInterface(type_name):
        dart_interface_name = self._renamer.RenameInterface(
            self._database.GetInterface(type_name))
      else:
        dart_interface_name = type_name
      return InterfaceIDLTypeInfo(type_name, type_data, dart_interface_name)

    if type_data.clazz == 'ListLike':
      return ListLikeIDLTypeInfo(type_name, type_data, self.TypeInfo(type_data.item_type))

    class_name = '%sIDLTypeInfo' % type_data.clazz
    return globals()[class_name](type_name, type_data)
