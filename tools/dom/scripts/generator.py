#!/usr/bin/python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""This module provides shared functionality for systems to generate
Dart APIs from the IDL database."""

import copy
import json
import monitored
import os
import re
from htmlrenamer import custom_html_constructors, html_interface_renames, \
    typed_array_renames

_pure_interfaces = monitored.Set('generator._pure_interfaces', [
    # TODO(sra): DOMStringMap should be a class implementing Map<String,String>.
    'DOMStringMap',
    'ChildNode',
    'EventListener',
    'GlobalEventHandlers',
    'MediaQueryListListener',
    'MutationCallback',
    'NavigatorID',
    'NavigatorOnLine',
    'ParentNode',
    'SVGExternalResourcesRequired',
    'SVGFilterPrimitiveStandardAttributes',
    'SVGFitToViewBox',
    'SVGTests',
    'SVGURIReference',
    'SVGZoomAndPan',
    'TimeoutHandler',
    'URLUtils',
    'URLUtilsReadOnly',
    'WindowBase64',
    'WindowEventHandlers',
    'WindowTimers',
    ])

def IsPureInterface(interface_name):
  return interface_name in _pure_interfaces

#
# Classes which have native constructors but which we are suppressing because
# they are not cross-platform.
#
_suppressed_native_constructors = monitored.Set(
    'generator._suppressed_native_constructors', [
  'DocumentFragment',
  'Range',
  'Text',
  ])

_custom_types = monitored.Set('generator._custom_types',
                              typed_array_renames.keys())

def IsCustomType(interface_name):
  return interface_name in _custom_types

_methods_with_named_formals = monitored.Set(
    'generator._methods_with_named_formals', [
  'DirectoryEntry.getDirectory',
  'DirectoryEntry.getFile',
  'Entry.copyTo',
  'Entry.moveTo',
  'HTMLInputElement.setRangeText',
  'HTMLTextAreaElement.setRangeText',
  'XMLHttpRequest.open',
  ])

def ReturnValueConversionHack(idl_type, value, interface_name):
  if idl_type == 'SVGMatrix':
    return '%sTearOff::create(%s)' % (idl_type, value)
  elif ((idl_type == 'SVGAngle' and interface_name != 'SVGAnimatedAngle')
      or (idl_type == 'SVGTransform' and interface_name == 'SVGSVGElement')):
    # Somewhere in the IDL it probably specifies whether we need to call
    # create or not.
    return 'SVGPropertyTearOff<%s>::create(%s)' % (idl_type, value)

  return value

#
# Renames for attributes that have names that are not legal Dart names.
#
_dart_attribute_renames = monitored.Dict('generator._dart_attribute_renames', {
    'default': 'defaultValue',
})

#
# Interface version of the DOM needs to delegate typed array constructors to a
# factory provider.
#
interface_factories = monitored.Dict('generator.interface_factories', {
})


#
# Custom native specs for the dart2js dom.
#
_dart2js_dom_custom_native_specs = monitored.Dict(
      'generator._dart2js_dom_custom_native_specs', {

    # Nodes with different tags in different browsers can be listed as multiple
    # tags here provided there is not conflict in usage (e.g. browser X has tag
    # T and no other browser has tag T).

    'AnalyserNode': 'AnalyserNode,RealtimeAnalyserNode',
    'AudioContext': 'AudioContext,webkitAudioContext',

    'ChannelMergerNode': 'ChannelMergerNode,AudioChannelMerger',
    'ChannelSplitterNode': 'ChannelSplitterNode,AudioChannelSplitter',

    'ClientRect': 'ClientRect,DOMRect',

    'CSSStyleDeclaration':
        #                    IE                   Firefox
        'CSSStyleDeclaration,MSStyleCSSProperties,CSS2Properties',

    'Clipboard': 'Clipboard,DataTransfer',

    'ApplicationCache':
        'ApplicationCache,DOMApplicationCache,OfflineResourceList',

    'Event':
        'Event,InputEvent,ClipboardEvent',

    'HTMLTableCellElement':
        'HTMLTableCellElement,HTMLTableDataCellElement,HTMLTableHeaderCellElement',

    'GainNode': 'GainNode,AudioGainNode',

    'IDBOpenDBRequest':
        'IDBOpenDBRequest,IDBVersionChangeRequest',

    'MouseEvent': 'MouseEvent,DragEvent,PointerEvent,MSPointerEvent',

    'MutationObserver': 'MutationObserver,WebKitMutationObserver',

    'NamedNodeMap': 'NamedNodeMap,MozNamedAttrMap',

    'NodeList': 'NodeList,RadioNodeList',

    'OscillatorNode': 'OscillatorNode,Oscillator',

    'PannerNode': 'PannerNode,AudioPannerNode',

    'RTCPeerConnection': 'RTCPeerConnection,mozRTCPeerConnection',

    'RTCIceCandidate': 'RTCIceCandidate,mozRTCIceCandidate',

    'RTCSessionDescription': 'RTCSessionDescription,mozRTCSessionDescription',

    'RTCDataChannel': 'RTCDataChannel,DataChannel',

    'ScriptProcessorNode': 'ScriptProcessorNode,JavaScriptAudioNode',

    'TransitionEvent': 'TransitionEvent,WebKitTransitionEvent',

    'WebGLLoseContext': 'WebGLLoseContext,WebGLExtensionLoseContext',

    'CSSKeyframeRule':
        'CSSKeyframeRule,MozCSSKeyframeRule,WebKitCSSKeyframeRule',

    'CSSKeyframesRule':
        'CSSKeyframesRule,MozCSSKeyframesRule,WebKitCSSKeyframesRule',

    'WheelEvent': 'WheelEvent,MouseWheelEvent,MouseScrollEvent',

}, dart2jsOnly=True)

def IsRegisteredType(type_name):
  return type_name in _idl_type_registry

def MakeNativeSpec(javascript_binding_name):
  if javascript_binding_name in _dart2js_dom_custom_native_specs:
    return _dart2js_dom_custom_native_specs[javascript_binding_name]
  else:
    # Make the class 'hidden' so it is dynamically patched at runtime.  This
    # is useful for browser compat.
    return javascript_binding_name


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

def GetCallbackInfo(interface):
  """For the given interface, find operations that take callbacks (for use in
  auto-transforming callbacks into futures)."""
  callback_handlers = [operation for operation in interface.operations
      if operation.id == 'handleEvent']
  if callback_handlers == []:
    callback_handlers = [operation for operation in interface.operations
                         if operation.id == 'handleItem']
  return AnalyzeOperation(interface, callback_handlers)

# Given a list of overloaded arguments, render dart arguments.
def _BuildArguments(args, interface, constructor=False):
  def IsOptional(argument):
    if 'Callback' in argument.ext_attrs:
      # Optional callbacks arguments are treated as optional arguments.
      return argument.optional
    if constructor:
      # FIXME: Optional constructors arguments should not be treated as
      # optional arguments.
      return argument.optional
    if 'ForceOptional' in argument.ext_attrs:
      return True
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
  return argument.optional and ('Default' not in argument.ext_attrs)\
      or 'ForceOptional' in argument.ext_attrs

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
  full_name = '%s.%s' % (interface.id, info.declared_name)
  info.requires_named_arguments = full_name in _methods_with_named_formals
  # The arguments in that the original operation took as callbacks (for
  # conversion to futures).
  info.callback_args = []
  return info

def ConvertToFuture(info):
  """Given an OperationInfo object, convert the operation's signature so that it
  instead uses futures instead of callbacks."""
  new_info = copy.deepcopy(info)
  def IsNotCallbackType(param):
    return 'Callback' not in param.type_id
  # Success callback is the first argument (change if this no longer holds).
  new_info.callback_args = filter(
      lambda x: not IsNotCallbackType(x), new_info.param_infos)
  new_info.param_infos = filter(IsNotCallbackType, new_info.param_infos)
  new_info.type_name = 'Future'

  return new_info


def AnalyzeConstructor(interface):
  """Returns an OperationInfo object for the constructor.

  Returns None if the interface has no Constructor.
  """
  if interface.id in _suppressed_native_constructors:
    return None

  if 'Constructor' in interface.ext_attrs:
    name = None
    overloads = interface.ext_attrs['Constructor']
    idl_args = [[] if f is None else f.arguments for f in overloads]
  elif 'NamedConstructor' in interface.ext_attrs:
    func_value = interface.ext_attrs.get('NamedConstructor')
    idl_args = [func_value.arguments]
    name = func_value.id
  else:
    return None

  info = OperationInfo()
  info.overloads = None
  info.idl_args = idl_args
  info.declared_name = name
  info.name = name
  info.constructor_name = ('_' if interface.id in custom_html_constructors
      else None)
  info.js_name = name
  info.type_name = interface.id
  info.param_infos = _BuildArguments(idl_args, interface, constructor=True)
  info.requires_named_arguments = False
  info.pure_dart_constructor = False
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
  if dart_type == 'dynamic':
    if comment:
      return '/*%s*/ ' % comment   # Just a comment foo(/*T*/ x)
    else:
      return ''                    # foo(x) looks nicer than foo(var|dynamic x)
  else:
    return dart_type + ' '


def TypeOrVar(dart_type, comment=None):
  """Returns string for declaring something with |dart_type| in a context
  where if a type is omitted, 'var' must be used instead."""
  if dart_type == 'dynamic':
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
    factory_parameters: A list of parameters used for custom designed Factory
        calls.
  """

  def __init__(self):
    self.factory_parameters = None

  def ParametersAsDecVarLists(self, rename_type, force_optional=False):
    """ Returns a tuple (required, optional, named), where:
      required is a list of parameter declarations corresponding to the
        required parameters
      optional is a list of parameter declarations corresponding to the
        optional parameters
      named is a boolean which is true if the optional parameters should
        be named
      A parameter declaration is a tuple (dec, var) where var is the
        variable name, and dec is a string suitable for declaring the
        variable in a parameter list.  That is, dec + var is a valid
        parameter declaration.
    """
    def FormatParam(param):
      dart_type = rename_type(param.type_id) if param.type_id else 'dynamic'
      return (TypeOrNothing(dart_type, param.type_id), param.name)
    required = []
    optional = []
    for param_info in self.param_infos:
      if param_info.is_optional:
        optional.append(FormatParam(param_info))
      else:
        if optional:
          raise Exception('Optional parameters cannot precede required ones: '
                          + str(params))
        required.append(FormatParam(param_info))
    needs_named = optional and self.requires_named_arguments and not force_optional
    return (required, optional, needs_named)

  def ParametersAsDecStringList(self, rename_type, force_optional=False):
    """Returns a list of strings where each string corresponds to a parameter
    declaration.  All of the optional/named parameters if any will appear as
    a single entry at the end of the list.
    """
    (required, optional, needs_named) = \
        self.ParametersAsDecVarLists(rename_type, force_optional)
    def FormatParam(dec):
        return dec[0] + dec[1]
    argtexts = map(FormatParam, required)
    if optional:
      left_bracket, right_bracket = '{}' if needs_named else '[]'
      argtexts.append(
          left_bracket +
          ', '.join(map(FormatParam, optional)) +
          right_bracket)
    return argtexts

  def ParametersAsDeclaration(self, rename_type, force_optional=False):
    p_list = self.ParametersAsDecStringList(rename_type, force_optional)
    return ', '.join(p_list)

  def NumberOfRequiredInDart(self):
    """ Returns a number of required arguments in Dart declaration of
    the operation.
    """
    return len(filter(lambda i: not i.is_optional, self.param_infos))

  def ParametersAsArgumentList(self, parameter_count=None):
    """Returns a string of the parameter names suitable for passing the
    parameters as arguments.
    """
    def param_name(param_info):
      if self.requires_named_arguments and param_info.is_optional:
        return '%s : %s' % (param_info.name, param_info.name)
      else:
        return param_info.name

    if parameter_count is None:
      parameter_count = len(self.param_infos)
    return ', '.join(map(param_name, self.param_infos[:parameter_count]))

  def ParametersAsListOfVariables(self, parameter_count=None):
    """Returns a list of the first parameter_count parameter names
    as raw variables.
    """
    if parameter_count is None:
      parameter_count = len(self.param_infos)
    return [p.name for p in self.param_infos[:parameter_count]]

  def ParametersAsStringOfVariables(self, parameter_count=None):
    """Returns a string containing the first parameter_count parameter names
    as raw variables, comma separated.
    """
    return ', '.join(self.ParametersAsListOfVariables(parameter_count))

  def IsStatic(self):
    is_static = self.overloads[0].is_static
    assert any([is_static == o.is_static for o in self.overloads])
    return is_static

  def _ConstructorFullName(self, rename_type):
    if self.constructor_name:
      return rename_type(self.type_name) + '.' + self.constructor_name
    else:
      # TODO(antonm): temporary ugly hack.
      # While in transition phase we allow both DOM's ArrayBuffer
      # and dart:typed_data's ByteBuffer for IDLs' ArrayBuffers,
      # hence ArrayBuffer is mapped to dynamic in arguments and return
      # values.  To compensate for that when generating ArrayBuffer itself,
      # we need to lie a bit:
      if self.type_name == 'ArrayBuffer': return 'ByteBuffer'
      return rename_type(self.type_name)

def ConstantOutputOrder(a, b):
  """Canonical output ordering for constants."""
  return cmp(a.id, b.id)


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
  return 'dynamic'

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

_serialize_SSV = Conversion('convertDartToNative_SerializedScriptValue',
                           'dynamic', 'dynamic')

dart2js_conversions = monitored.Dict('generator.dart2js_conversions', {
    'Date get':
      Conversion('convertNativeToDart_DateTime', 'dynamic', 'DateTime'),
    'Date set':
      Conversion('convertDartToNative_DateTime', 'DateTime', 'dynamic'),
    # Wrap non-local Windows.  We need to check EventTarget (the base type)
    # as well.  Note, there are no functions that take a non-local Window
    # as a parameter / setter.
    'Window get':
      Conversion('_convertNativeToDart_Window', 'dynamic', 'WindowBase'),
    'EventTarget get':
      Conversion('_convertNativeToDart_EventTarget', 'dynamic',
                 'EventTarget'),
    'EventTarget set':
      Conversion('_convertDartToNative_EventTarget', 'EventTarget',
                 'dynamic'),

    'WebGLContextAttributes get':
      Conversion('convertNativeToDart_ContextAttributes', 'dynamic',
                 'ContextAttributes'),

    'ImageData get':
      Conversion('convertNativeToDart_ImageData', 'dynamic', 'ImageData'),
    'ImageData set':
      Conversion('convertDartToNative_ImageData', 'ImageData', 'dynamic'),

    'Dictionary get':
      Conversion('convertNativeToDart_Dictionary', 'dynamic', 'Map'),
    'Dictionary set':
      Conversion('convertDartToNative_Dictionary', 'Map', 'dynamic'),

    'sequence<DOMString> set':
      Conversion('convertDartToNative_StringArray', 'List<String>', 'List'),

    'any set IDBObjectStore.add': _serialize_SSV,
    'any set IDBObjectStore.put': _serialize_SSV,
    'any set IDBCursor.update': _serialize_SSV,

    # postMessage
    'any set MessagePort.postMessage': _serialize_SSV,
    'SerializedScriptValue set Window.postMessage': _serialize_SSV,

    '* get CustomEvent.detail':
      Conversion('convertNativeToDart_SerializedScriptValue',
                 'dynamic', 'dynamic'),

    # receiving message via MessageEvent
    '* get MessageEvent.data':
      Conversion('convertNativeToDart_SerializedScriptValue',
                 'dynamic', 'dynamic'),

    '* get History.state':
      Conversion('convertNativeToDart_SerializedScriptValue',
                 'dynamic', 'dynamic'),

    '* get PopStateEvent.state':
      Conversion('convertNativeToDart_SerializedScriptValue',
                 'dynamic', 'dynamic'),

    # IDBAny is problematic.  Some uses are just a union of other IDB types,
    # which need no conversion..  Others include data values which require
    # serialized script value processing.
    '* get IDBCursorWithValue.value':
      Conversion('_convertNativeToDart_IDBAny', 'dynamic', 'dynamic'),

    # This is problematic.  The result property of IDBRequest is used for
    # all requests.  Read requests like IDBDataStore.getObject need
    # conversion, but other requests like opening a database return
    # something that does not need conversion.
    '* get IDBRequest.result':
      Conversion('_convertNativeToDart_IDBAny', 'dynamic', 'dynamic'),

    # "source: On getting, returns the IDBObjectStore or IDBIndex that the
    # cursor is iterating. ...".  So we should not try to convert it.
    '* get IDBCursor.source': None,

    # Should be either a DOMString, an Array of DOMStrings or null.
    '* get IDBObjectStore.keyPath': None,

    '* get XMLHttpRequest.response':
      Conversion('_convertNativeToDart_XHR_Response',
                 'dynamic', 'dynamic'),
}, dart2jsOnly=True)

def FindConversion(idl_type, direction, interface, member):
  table = dart2js_conversions
  return (table.get('%s %s %s.%s' % (idl_type, direction, interface, member)) or
          table.get('* %s %s.%s' % (direction, interface, member)) or
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

  def list_item_type(self):
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
    return self.native_type()

  def to_native_info(self, idl_node, interface_name, callback_name):
    cls = self.bindings_class()

    if 'Callback' in idl_node.ext_attrs:
      return '%s.release()', 'OwnPtr<%s>' % self.native_type(), cls, 'create'

    # This is a hack to handle property references correctly.
    if (self.native_type() in ['SVGPropertyTearOff<SVGAngle>',
          'SVGPropertyTearOff<SVGAngle>*', 'SVGMatrixTearOff']
        and (callback_name != 'createSVGTransformFromMatrixCallback'
          or interface_name != 'SVGTransformList')):
      argument_expression_template = '%s->propertyReference()'
      type = '%s*' % self.native_type()
    elif self.custom_to_native():
      type = 'RefPtr<%s>' % self.native_type()
      argument_expression_template = '%s.get()'
    else:
      type = '%s*' % self.native_type()
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
        'Uint8ClampedArray',
        'Uint16Array',
        'Uint32Array',
    ]

    if self._idl_type in WTF_INCLUDES:
      return ['<wtf/%s.h>' % self.native_type()]

    # TODO(vsm): Why does this need special casing?
    if self._idl_type == 'AnalyserNode':
      return ['"AnalyserNode.h"', '<wtf/Uint8Array.h>']

    if not self._idl_type.startswith('SVG'):
      return ['"%s.h"' % self.native_type()]

    include = self._idl_type
    return ['"%s.h"' % include] + _svg_supplemental_includes

  def receiver(self):
    return 'receiver->'

  def conversion_includes(self):
    includes = [self._idl_type] + (self._data.conversion_includes or [])
    return ['"Dart%s.h"' % include for include in includes]

  def to_dart_conversion(self, value, interface_name=None, attributes=None):
    return 'Dart%s::toDart(%s)' % (self._idl_type, value)

  def return_to_dart_conversion(self, value, auto_dart_scope_setup,
                                interface_name=None, attributes=None):
    auto_dart_scope='true' if auto_dart_scope_setup else 'false'
    return 'Dart%s::returnToDart(args, %s, %s)' % (self._idl_type,
                                                   ReturnValueConversionHack(self._idl_type, value, interface_name),
                                                   auto_dart_scope)

  def custom_to_dart(self):
    return self._data.custom_to_dart


class InterfaceIDLTypeInfo(IDLTypeInfo):
  def __init__(self, idl_type, data, dart_interface_name, type_registry):
    super(InterfaceIDLTypeInfo, self).__init__(idl_type, data)
    self._dart_interface_name = dart_interface_name
    self._type_registry = type_registry

  def dart_type(self):
    if self._data.dart_type:
      return self._data.dart_type
    if self.list_item_type() and not self.has_generated_interface():
      return 'List<%s>' % self._type_registry.TypeInfo(self._data.item_type).dart_type()
    return self._dart_interface_name

  def narrow_dart_type(self):
    if self.list_item_type():
      return self.implementation_name()
    # TODO(podivilov): only primitive and collection types should override
    # dart_type.
    if self._data.dart_type != None:
      return self.dart_type()
    if IsPureInterface(self.idl_type()):
      return self.idl_type()
    return self.interface_name()

  def interface_name(self):
    return self._dart_interface_name

  def implementation_name(self):
    implementation_name = self._dart_interface_name

    if not self.has_generated_interface():
      implementation_name = '_%s' % implementation_name

    return implementation_name

  def native_type(self):
    database = self._type_registry._database

    if database.HasInterface(self.idl_type()):
      interface = database.GetInterface(self.idl_type())
      if 'ImplementedAs' in interface.ext_attrs:
        return interface.ext_attrs['ImplementedAs']
    return super(InterfaceIDLTypeInfo, self).native_type()

  def has_generated_interface(self):
    return not self._data.suppress_interface

  def list_item_type(self):
    return self._data.item_type

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

  def implementation_name(self):
    return ""


def array_type(data_type):
  matched = re.match(r'([\w\d_\s]+)\[\]', data_type)
  if not matched:
      return None
  return matched.group(1)

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

  def to_native_info(self, idl_node, interface_name, callback_name):
    item_native_type = self._item_info.vector_to_dart_template_parameter()
    if isinstance(self._item_info, PrimitiveIDLTypeInfo):
      return '%s', 'Vector<%s>' % item_native_type, 'DartUtilities', 'toNativeVector<%s>' % item_native_type
    return '%s', 'Vector< RefPtr<%s> >' % item_native_type, 'DartUtilities', 'toNativeVector< RefPtr<%s> >' % item_native_type

  def parameter_type(self):
    native_type = self.native_type()
    if array_type(native_type):
      return 'const Vector<RefPtr<%s> > &' % array_type(native_type)

    return native_type

  def pass_native_by_ref(self): return True

  def to_dart_conversion(self, value, interface_name=None, attributes=None):
    if isinstance(self._item_info, PrimitiveIDLTypeInfo):
      return 'DartDOMWrapper::vectorToDart(%s)' % value
    return 'DartDOMWrapper::vectorToDart<%s>(%s)' % (self._item_info.bindings_class(), value)

  def return_to_dart_conversion(self, value, auto_dart_scope_setup=True,
                                interface_name=None, attributes=None):
    return 'Dart_SetReturnValue(args, %s)' % self.to_dart_conversion(
        value,
        interface_name,
        attributes)

  def conversion_includes(self):
    return self._item_info.conversion_includes()


class DOMStringArrayTypeInfo(SequenceIDLTypeInfo):
  def __init__(self, data, item_info):
    super(DOMStringArrayTypeInfo, self).__init__('DOMString[]', data, item_info)

  def to_native_info(self, idl_node, interface_name, callback_name):
    return '%s', 'RefPtr<DOMStringList>', 'DartDOMStringList', 'toNative'

  def pass_native_by_ref(self): return False

  def implementation_name(self):
    return ""


class PrimitiveIDLTypeInfo(IDLTypeInfo):
  def __init__(self, idl_type, data):
    super(PrimitiveIDLTypeInfo, self).__init__(idl_type, data)

  def vector_to_dart_template_parameter(self):
    # Ugly hack. Usually IDLs floats are treated as C++ doubles, however
    # sequence<float> should map to Vector<float>
    if self.idl_type() == 'float': return 'float'
    return self.native_type()

  def to_native_info(self, idl_node, interface_name, callback_name):
    type = self.native_type()
    if type == 'SerializedScriptValue':
      type = 'RefPtr<%s>' % type
    if type == 'String':
      type = 'DartStringAdapter'
    target_type = self._capitalized_native_type()
    if self.idl_type() == 'Date':
      target_type = 'Date'
    return '%s', type, 'DartUtilities', 'dartTo%s' % target_type

  def parameter_type(self):
    if self.native_type() == 'String':
      return 'const String&'
    return self.native_type()

  def conversion_includes(self):
    return []

  def to_dart_conversion(self, value, interface_name=None, attributes=None):
    # TODO(antonm): if there are more instances of the case
    # when conversion depends on both Dart type and C++ type,
    # consider introducing a corresponding argument/class.
    if self.idl_type() == 'Date':
      function_name = 'date'
    else:
      function_name = self._capitalized_native_type()
      function_name = function_name[0].lower() + function_name[1:]
    function_name = 'DartUtilities::%sToDart' % function_name
    if attributes and 'TreatReturnedNullStringAs' in attributes:
      function_name += 'WithNullCheck'
    return '%s(%s)' % (function_name, value)

  def return_to_dart_conversion(self, value, auto_dart_scope_setup=True,
                                interface_name=None, attributes=None):
    return 'Dart_SetReturnValue(args, %s)' % self.to_dart_conversion(
        value,
        interface_name,
        attributes)

  def webcore_getter_name(self):
    return self._data.webcore_getter_name

  def webcore_setter_name(self):
    return self._data.webcore_setter_name

  def _capitalized_native_type(self):
    return re.sub(r'(^| )([a-z])', lambda x: x.group(2).upper(), self.native_type())


class SVGTearOffIDLTypeInfo(InterfaceIDLTypeInfo):
  def __init__(self, idl_type, data, interface_name, type_registry):
    super(SVGTearOffIDLTypeInfo, self).__init__(
        idl_type, data, interface_name, type_registry)

  def native_type(self):
    if self._data.native_type:
      return self._data.native_type
    tear_off_type = 'SVGPropertyTearOff'
    if self._idl_type.endswith('List'):
      tear_off_type = 'SVGListPropertyTearOff'
    return '%s<%s>' % (tear_off_type, self._idl_type)

  def receiver(self):
    return 'receiver->'

  def to_conversion_cast(self, value, interface_name, attributes):
    svg_primitive_types = ['SVGLength', 'SVGMatrix',
        'SVGNumber', 'SVGPoint', 'SVGRect', 'SVGTransform']

    # This is a hack. We either need to figure out the right way to derive this
    # information from the IDL or remove this generator.
    if self.idl_type() != 'SVGTransformList':
      return value

    conversion_cast = 'static_cast<%s*>(%s)'
    conversion_cast = conversion_cast % (self.native_type(), value)
    return '%s' % (conversion_cast)

  def to_dart_conversion(self, value, interface_name, attributes):
    return 'Dart%s::toDart(%s)' % (self._idl_type, self.to_conversion_cast(value, interface_name, attributes))

  def return_to_dart_conversion(self, value, auto_dart_scope_setup,
                                interface_name, attr):
    auto_dart_scope='true' if auto_dart_scope_setup else 'false'
    return 'Dart%s::returnToDart(args, %s, %s)' % (self._idl_type,
                                                   self.to_conversion_cast(
                                                       ReturnValueConversionHack(self._idl_type, value, interface_name),
                                                       interface_name,
                                                       attr),
                                                   auto_dart_scope)

  def argument_expression(self, name, interface_name):
    return name

class TypedListIDLTypeInfo(InterfaceIDLTypeInfo):
  def __init__(self, idl_type, data, interface_name, type_registry):
    super(TypedListIDLTypeInfo, self).__init__(
        idl_type, data, interface_name, type_registry)

  def conversion_includes(self):
    return [ '"wtf/%s.h"' % self._idl_type ]

  def to_dart_conversion(self, value, interface_name, attributes):
    return 'DartUtilities::arrayBufferViewToDart(%s)' % value

  def return_to_dart_conversion(self, value, auto_dart_scope_setup,
                                interface_name, attributes):
    return 'Dart_SetReturnValue(args, %s)' % self.to_dart_conversion(
        value,
        interface_name,
        attributes)

  def to_native_info(self, idl_node, interface_name, callback_name):
    return '%s.get()', 'RefPtr<%s>' % self._idl_type, 'DartUtilities', 'dartTo%s' % self._idl_type


class BasicTypedListIDLTypeInfo(InterfaceIDLTypeInfo):
  def __init__(self, idl_type, data, interface_name, type_registry):
    super(BasicTypedListIDLTypeInfo, self).__init__(
        idl_type, data, interface_name, type_registry)

  def conversion_includes(self):
    return []

  def to_dart_conversion(self, value, interface_name, attributes):
    function_name = 'DartUtilities::%sToDart' % self._idl_type
    function_name = function_name[0].lower() + function_name[1:]
    return '%s(%s)' % (function_name, value)

  def return_to_dart_conversion(self, value, auto_dart_scope_setup,
                                interface_name, attributes):
    return 'Dart_SetReturnValue(args, %s)' % self.to_dart_conversion(
        value,
        interface_name,
        attributes)

  def to_native_info(self, idl_node, interface_name, callback_name):
    return '%s.get()', 'RefPtr<%s>' % self._idl_type, 'DartUtilities', 'dartTo%s' % self._idl_type


class TypeData(object):
  def __init__(self, clazz, dart_type=None, native_type=None,
               merged_interface=None, merged_into=None,
               custom_to_dart=False, custom_to_native=False,
               conversion_includes=None,
               webcore_getter_name='getAttribute',
               webcore_setter_name='setAttribute',
               item_type=None, suppress_interface=False):
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
    self.item_type = item_type
    self.suppress_interface = suppress_interface


def TypedListTypeData(item_type):
  return TypeData(clazz='TypedList', item_type=item_type)


_idl_type_registry = monitored.Dict('generator._idl_type_registry', {
    'boolean': TypeData(clazz='Primitive', dart_type='bool', native_type='bool',
                        webcore_getter_name='hasAttribute',
                        webcore_setter_name='setBooleanAttribute'),
    'byte': TypeData(clazz='Primitive', dart_type='int', native_type='int'),
    'octet': TypeData(clazz='Primitive', dart_type='int', native_type='int'),
    'short': TypeData(clazz='Primitive', dart_type='int', native_type='int'),
    'unsigned short': TypeData(clazz='Primitive', dart_type='int',
        native_type='int'),
    'int': TypeData(clazz='Primitive', dart_type='int'),
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

    'any': TypeData(clazz='Primitive', dart_type='Object', native_type='ScriptValue'),
    'Array': TypeData(clazz='Primitive', dart_type='List'),
    'custom': TypeData(clazz='Primitive', dart_type='dynamic'),
    'ClientRect': TypeData(clazz='Interface',
        dart_type='Rectangle', suppress_interface=True),
    'Date': TypeData(clazz='Primitive', dart_type='DateTime', native_type='double'),
    'DOMObject': TypeData(clazz='Primitive', dart_type='Object', native_type='ScriptValue'),
    'DOMString': TypeData(clazz='Primitive', dart_type='String', native_type='String'),
    # TODO(vsm): This won't actually work until we convert the Map to
    # a native JS Map for JS DOM.
    'Dictionary': TypeData(clazz='Primitive', dart_type='Map'),
    'DOMTimeStamp': TypeData(clazz='Primitive', dart_type='int', native_type='unsigned long long'),
    'object': TypeData(clazz='Primitive', dart_type='Object', native_type='ScriptValue'),
    'ObjectArray': TypeData(clazz='Primitive', dart_type='List'),
    'PositionOptions': TypeData(clazz='Primitive', dart_type='Object'),
    # TODO(sra): Come up with some meaningful name so that where this appears in
    # the documentation, the user is made aware that only a limited subset of
    # serializable types are actually permitted.
    'SerializedScriptValue': TypeData(clazz='Primitive', dart_type='dynamic'),
    'sequence': TypeData(clazz='Primitive', dart_type='List'),
    'void': TypeData(clazz='Primitive', dart_type='void'),

    'CSSRule': TypeData(clazz='Interface', conversion_includes=['CSSImportRule']),
    'DOMStringMap': TypeData(clazz='Interface', dart_type='Map<String, String>'),
    'Window': TypeData(clazz='Interface', custom_to_dart=True),
    'Element': TypeData(clazz='Interface', merged_interface='HTMLElement',
        custom_to_dart=True),
    'EventListener': TypeData(clazz='Interface', custom_to_native=True),
    'EventHandler': TypeData(clazz='Interface', custom_to_native=True),
    'EventTarget': TypeData(clazz='Interface', custom_to_native=True),
    'HTMLElement': TypeData(clazz='Interface', merged_into='Element',
        custom_to_dart=True),
    'IDBAny': TypeData(clazz='Interface', dart_type='dynamic', custom_to_native=True),
    'MutationRecordArray': TypeData(clazz='Interface',  # C++ pass by pointer.
        native_type='MutationRecordArray', dart_type='List<MutationRecord>'),
    'StyleSheet': TypeData(clazz='Interface', conversion_includes=['CSSStyleSheet']),
    'SVGElement': TypeData(clazz='Interface', custom_to_dart=True),

    'ClientRectList': TypeData(clazz='Interface',
        item_type='ClientRect', dart_type='List<Rectangle>',
        suppress_interface=True),
    'CSSRuleList': TypeData(clazz='Interface',
        item_type='CSSRule', suppress_interface=True),
    'CSSValueList': TypeData(clazz='Interface',
        item_type='CSSValue', suppress_interface=True),
    'MimeTypeArray': TypeData(clazz='Interface', item_type='MimeType'),
    'PluginArray': TypeData(clazz='Interface', item_type='Plugin'),
    'DOMStringList': TypeData(clazz='Interface', item_type='DOMString',
        dart_type='List<String>', custom_to_native=True),
    'FileList': TypeData(clazz='Interface', item_type='File',
        dart_type='List<File>'),
    'Future': TypeData(clazz='Interface', dart_type='Future'),
    'GamepadList': TypeData(clazz='Interface', item_type='Gamepad',
        suppress_interface=True),
    'GLenum': TypeData(clazz='Primitive', dart_type='int',
        native_type='unsigned'),
    'HTMLCollection': TypeData(clazz='Interface', item_type='Node',
        dart_type='List<Node>'),
    'NamedNodeMap': TypeData(clazz='Interface', item_type='Node'),
    'NodeList': TypeData(clazz='Interface', item_type='Node',
                         suppress_interface=False, dart_type='List<Node>'),
    'SVGElementInstanceList': TypeData(clazz='Interface',
        item_type='SVGElementInstance', suppress_interface=True),
    'SourceBufferList': TypeData(clazz='Interface', item_type='SourceBuffer'),
    'SpeechGrammarList': TypeData(clazz='Interface', item_type='SpeechGrammar'),
    'SpeechInputResultList': TypeData(clazz='Interface',
        item_type='SpeechInputResult', suppress_interface=True),
    'SpeechRecognitionResultList': TypeData(clazz='Interface',
        item_type='SpeechRecognitionResult', suppress_interface=True),
    'SQLResultSetRowList': TypeData(clazz='Interface', item_type='Dictionary'),
    'StyleSheetList': TypeData(clazz='Interface',
        item_type='StyleSheet', suppress_interface=True),
    'TextTrackCueList': TypeData(clazz='Interface', item_type='TextTrackCue'),
    'TextTrackList': TypeData(clazz='Interface', item_type='TextTrack'),
    'TouchList': TypeData(clazz='Interface', item_type='Touch'),

    'Float32Array': TypedListTypeData('double'),
    'Float64Array': TypedListTypeData('double'),
    'Int8Array': TypedListTypeData('int'),
    'Int16Array': TypedListTypeData('int'),
    'Int32Array': TypedListTypeData('int'),
    'Uint8Array': TypedListTypeData('int'),
    'Uint8ClampedArray': TypedListTypeData('int'),
    'Uint16Array': TypedListTypeData('int'),
    'Uint32Array': TypedListTypeData('int'),

    'ArrayBufferView': TypeData(clazz='BasicTypedList'),
    'ArrayBuffer': TypeData(clazz='BasicTypedList'),

    'SVGAngle': TypeData(clazz='SVGTearOff', native_type='SVGPropertyTearOff<SVGAngle>'),
    'SVGLength': TypeData(clazz='SVGTearOff', native_type='SVGLengthTearOff'),
    'SVGLengthList': TypeData(clazz='SVGTearOff', item_type='SVGLength', native_type='SVGLengthListTearOff'),
    'SVGMatrix': TypeData(clazz='SVGTearOff', native_type='SVGMatrixTearOff'),
    'SVGNumber': TypeData(clazz='SVGTearOff', native_type='SVGNumberTearOff'),
    'SVGNumberList': TypeData(clazz='SVGTearOff', item_type='SVGNumber', native_type='SVGNumberListTearOff'),
    'SVGPathSegList': TypeData(clazz='SVGTearOff', item_type='SVGPathSeg',
        native_type='SVGPathSegListPropertyTearOff'),
    'SVGPoint': TypeData(clazz='SVGTearOff', native_type='SVGPointTearOff'),
    'SVGPointList': TypeData(clazz='SVGTearOff', native_type='SVGPointListTearOff'),
    'SVGPreserveAspectRatio': TypeData(clazz='SVGTearOff', native_type='SVGPreserveAspectRatioTearOff'),
    'SVGRect': TypeData(clazz='SVGTearOff', native_type='SVGRectTearOff'),
    'SVGStringList': TypeData(clazz='SVGTearOff', item_type='DOMString',
        native_type='SVGStringListTearOff'),
    'SVGTransform': TypeData(clazz='SVGTearOff', native_type="SVGPropertyTearOff<SVGTransform>"),
    'SVGTransformList': TypeData(clazz='SVGTearOff', item_type='SVGTransform',
        native_type='SVGTransformListPropertyTearOff'),
})

_svg_supplemental_includes = [
    '"core/svg/properties/SVGPropertyTraits.h"',
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
      type_data = TypeData('Sequence')
      item_info = self.TypeInfo(match.group(1) or match.group(2))
      # TODO(vsm): Generalize this code.
      if 'SourceInfo' in type_name:
        type_data.native_type = 'const Vector<RefPtr<SourceInfo> >& '
      return SequenceIDLTypeInfo(type_name, type_data, item_info)

    if not type_name in _idl_type_registry:
      if self._database.HasEnum(type_name):
        return PrimitiveIDLTypeInfo(
            type_name,
            TypeData(clazz='Primitive', dart_type='String', native_type='String'))

      interface = self._database.GetInterface(type_name)
      if 'Callback' in interface.ext_attrs:
        return CallbackIDLTypeInfo(type_name, TypeData('Callback',
            self._renamer.DartifyTypeName(type_name)))
      return InterfaceIDLTypeInfo(
          type_name,
          TypeData('Interface'),
          self._renamer.RenameInterface(interface),
          self)

    type_data = _idl_type_registry.get(type_name)

    if type_data.clazz == 'Interface':
      if self._database.HasInterface(type_name):
        dart_interface_name = self._renamer.RenameInterface(
            self._database.GetInterface(type_name))
      else:
        dart_interface_name = self._renamer.DartifyTypeName(type_name)
      return InterfaceIDLTypeInfo(type_name, type_data, dart_interface_name,
                                  self)

    if type_data.clazz == 'SVGTearOff':
      dart_interface_name = self._renamer.RenameInterface(
          self._database.GetInterface(type_name))
      return SVGTearOffIDLTypeInfo(
          type_name, type_data, dart_interface_name, self)

    if type_data.clazz == 'TypedList':
      dart_interface_name = self._renamer.RenameInterfaceId(type_name)
      return TypedListIDLTypeInfo(
          type_name, type_data, dart_interface_name, self)

    if type_data.clazz == 'BasicTypedList':
      if type_name == 'ArrayBuffer':
        dart_interface_name = 'ByteBuffer'
      else:
        dart_interface_name = self._renamer.RenameInterfaceId(type_name)
      return BasicTypedListIDLTypeInfo(
          type_name, type_data, dart_interface_name, self)

    class_name = '%sIDLTypeInfo' % type_data.clazz
    return globals()[class_name](type_name, type_data)
