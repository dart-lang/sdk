#!/usr/bin/python
#
# Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""Generates sdk/lib/_blink/dartium/_blink_dartium.dart file."""

import os

from generator import AnalyzeOperation, AnalyzeConstructor

HEADER = """/* Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file.
 *
 * DO NOT EDIT
 * Auto-generated _blink library.
 */
library dart.dom._blink;

import 'dart:js' as js;
import 'dart:html' show DomException;
// This is a place to put custom renames if we need them.
final resolverMap = {
};

dynamic resolver(String s) {
"""

END_RESOLVER = """
  // Failed to find it, check for custom renames
  dynamic obj = resolverMap[s];
  if (obj != null) return obj;
  throw("No such interface exposed in blink: ${s}");
}

"""

BLINK_UTILS = """
// _Utils native entry points
class Blink_Utils {
  static window() native "Utils_window";

  static forwardingPrint(message) native "Utils_forwardingPrint";

  static spawnDomUri(uri) native "Utils_spawnDomUri";

  static void spawnDomHelper(Function f, int replyTo) native "Utils_spawnDomHelper";

  static register(document, tag, customType, extendsTagName) native "Utils_register";

  static createElement(document, tagName) native "Utils_createElement";

  static constructElement(element_type, jsObject) native "Utils_constructor_create";

  static initializeCustomElement(element) native "Utils_initializeCustomElement";

  static changeElementWrapper(element, type) native "Utils_changeElementWrapper";
}

class Blink_DOMWindowCrossFrame {
  // FIXME: Return to using explicit cross frame entry points after roll to M35
  static get_history(_DOMWindowCrossFrame) native "Window_history_cross_frame_Getter";

  static get_location(_DOMWindowCrossFrame) native "Window_location_cross_frame_Getter";

  static get_closed(_DOMWindowCrossFrame) native "Window_closed_Getter";

  static get_opener(_DOMWindowCrossFrame) native "Window_opener_Getter";

  static get_parent(_DOMWindowCrossFrame) native "Window_parent_Getter";

  static get_top(_DOMWindowCrossFrame) native "Window_top_Getter";

  static close(_DOMWindowCrossFrame) native "Window_close_Callback";

  static postMessage(_DOMWindowCrossFrame, message, targetOrigin, [messagePorts]) native "Window_postMessage_Callback";
}

class Blink_HistoryCrossFrame {
  // _HistoryCrossFrame native entry points
  static back(_HistoryCrossFrame) native "History_back_Callback";

  static forward(_HistoryCrossFrame) native "History_forward_Callback";

  static go(_HistoryCrossFrame, distance) native "History_go_Callback";
}

class Blink_LocationCrossFrame {
  // _LocationCrossFrame native entry points
  static set_href(_LocationCrossFrame, h) native "Location_href_Setter";
}

class Blink_DOMStringMap {
  // _DOMStringMap native entry  points
  static containsKey(_DOMStringMap, key) native "DOMStringMap_containsKey_Callback";

  static item(_DOMStringMap, key) native "DOMStringMap_item_Callback";

  static setItem(_DOMStringMap, key, value) native "DOMStringMap_setItem_Callback";

  static remove(_DOMStringMap, key) native "DOMStringMap_remove_Callback";

  static get_keys(_DOMStringMap) native "DOMStringMap_getKeys_Callback";
}

// Calls through JsNative but returns DomException instead of error strings.
class Blink_JsNative_DomException {
  static getProperty(js.JsObject o, name) {
    try {
      return js.JsNative.getProperty(o, name);
    } catch (e) {
      // Re-throw any errors (returned as a string) as a DomException.
      throw new DomException.jsInterop(e);
    }
  }

  static callMethod(js.JsObject o, String method, List args) {
    try {
      return js.JsNative.callMethod(o, method, args);
    } catch (e) {
      // Re-throw any errors (returned as a string) as a DomException.
      throw new DomException.jsInterop(e);
    }
  }
}"""

CLASS_DEFINITION = """class Blink%s {
  static final instance = new Blink%s();

"""

CLASS_DEFINITION_EXTENDS = """class Blink%s extends Blink%s {
  static final instance = new Blink%s();

"""

#(interface_name)
CONSTRUCTOR_0 = '  constructorCallback_0_() => new js.JsObject(Blink_JsNative_DomException.getProperty(js.context, "%s"), []);\n\n'

#(argument_count, arguments, interface_name, arguments)
CONSTRUCTOR_ARGS = '  constructorCallback_%s_(%s) => new js.JsObject(Blink_JsNative_DomException.getProperty(js.context, "%s"), [%s]);\n\n'

#(attribute_name, attribute_name)
ATTRIBUTE_GETTER = '  %s_Getter_(mthis) => Blink_JsNative_DomException.getProperty(mthis, "%s");\n\n'
ATTRIBUTE_SETTER = '  %s_Setter_(mthis, __arg_0) => mthis["%s"] = __arg_0;\n\n'

#(operation_name, operationName)
OPERATION_0 = '  %s_Callback_0_(mthis) => Blink_JsNative_DomException.callMethod(mthis, "%s", []);\n\n'

#(operation_name, argument_count, arguments, operation_name, arguments)
ARGUMENT_NUM = "__arg_%s"
OPERATION_ARGS = '  %s_Callback_%s_(mthis, %s) => Blink_JsNative_DomException.callMethod(mthis, "%s", [%s]);\n\n'

CLASS_DEFINITION_END = """}

"""

def ConstantOutputOrder(a, b):
  """Canonical output ordering for constants."""
  return cmp(a.id, b.id)

def generate_parameter_entries(param_infos):
    optional_default_args = 0;
    for argument in param_infos:
      if argument.is_optional:
        optional_default_args += 1

    arg_count = len(param_infos)
    min_arg_count = arg_count - optional_default_args
    lb = min_arg_count - 2 if min_arg_count > 2 else 0
    return (lb, arg_count + 1)

def Generate_Blink(output_dir, database, type_registry):
  blink_filename = os.path.join(output_dir, '_blink_dartium.dart')
  blink_file = open(blink_filename, 'w')

  blink_file.write(HEADER);

  interfaces = database.GetInterfaces()
  for interface in interfaces:
    name = interface.id
    resolver_entry = '  if (s == "%s") return Blink%s.instance;\n' % (name, name)
    blink_file.write(resolver_entry)

  blink_file.write(END_RESOLVER);

  for interface in interfaces:
    name = interface.id

    if interface.parents and len(interface.parents) > 0 and interface.parents[0].id:
      extends = interface.parents[0].id
      class_def = CLASS_DEFINITION_EXTENDS % (name, extends, name)
    else:
      class_def = CLASS_DEFINITION % (name, name)
    blink_file.write(class_def);

    analyzed_constructors = AnalyzeConstructor(interface)
    if analyzed_constructors:
      _Emit_Blink_Constructors(blink_file, analyzed_constructors)
    elif 'Constructor' in interface.ext_attrs:
      # Zero parameter constructor.
      blink_file.write(CONSTRUCTOR_0 % name)

    _Process_Attributes(blink_file, interface.attributes)
    _Process_Operations(blink_file, interface, interface.operations)

    secondary_parents = database.TransitiveSecondaryParents(interface, False)
    for secondary in secondary_parents:
      _Process_Attributes(blink_file, secondary.attributes)
      _Process_Operations(blink_file, secondary, secondary.operations)

    blink_file.write(CLASS_DEFINITION_END);

  blink_file.write(BLINK_UTILS)

  blink_file.close()

def _Emit_Blink_Constructors(blink_file, analyzed_constructors):
  (arg_min_count, arg_max_count) = generate_parameter_entries(analyzed_constructors.param_infos)
  name = analyzed_constructors.js_name
  if not(name):
    name = analyzed_constructors.type_name

  for callback_index in range(arg_min_count, arg_max_count):
    if callback_index == 0:
      blink_file.write(CONSTRUCTOR_0 % (name))
    else:
      arguments = []
      for i in range(0, callback_index):
        arguments.append(ARGUMENT_NUM % i)
      argument_list = ', '.join(arguments)
      blink_file.write(CONSTRUCTOR_ARGS % (callback_index, argument_list, name, argument_list))

def _Process_Attributes(blink_file, attributes):
  # Emit an interface's attributes and operations.
  for attribute in sorted(attributes, ConstantOutputOrder):
    name = attribute.id
    if attribute.is_read_only:
      blink_file.write(ATTRIBUTE_GETTER % (name, name))
    else:
      blink_file.write(ATTRIBUTE_GETTER % (name, name))
      blink_file.write(ATTRIBUTE_SETTER % (name, name))

def _Process_Operations(blink_file, interface, operations):
  analyzeOperations = []

  for operation in sorted(operations, ConstantOutputOrder):
    if len(analyzeOperations) == 0:
      analyzeOperations.append(operation)
    else:
      if analyzeOperations[0].id == operation.id:
        # Handle overloads
        analyzeOperations.append(operation)
      else:
        _Emit_Blink_Operation(blink_file, interface, analyzeOperations)
        analyzeOperations = [operation]
  if len(analyzeOperations) > 0:
    _Emit_Blink_Operation(blink_file, interface, analyzeOperations)

def _Emit_Blink_Operation(blink_file, interface, analyzeOperations):
  analyzed = AnalyzeOperation(interface, analyzeOperations)
  (arg_min_count, arg_max_count) = generate_parameter_entries(analyzed.param_infos)
  name = analyzed.js_name

  for callback_index in range(arg_min_count, arg_max_count):
    if callback_index == 0:
      blink_file.write(OPERATION_0 % (name, name))
    else:
      arguments = []
      for i in range(0, callback_index):
        arguments.append(ARGUMENT_NUM % i)
      argument_list = ', '.join(arguments)
      blink_file.write(OPERATION_ARGS % (name, callback_index, argument_list, name, argument_list))
