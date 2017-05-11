#!/usr/bin/python
#
# Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

"""Generates sdk/lib/_blink/dartium/_blink_dartium.dart file."""

import os
from sets import Set
from generator import AnalyzeOperation, AnalyzeConstructor

# This is list of all methods with native c++ implementations
# If performing a dartium merge, the best practice is to comment out this list,
# ensure everything runs, and then uncomment this list which might possibly
# introduce breaking changes due to changes to these method signatures.
_js_custom_members = Set([
    'Document.createElement',
    'Element.id',
    'Element.tagName',
    'Element.className',
    'Element.setAttribute',
    'Element.getAttribute',
    # Consider adding this method so there is a fast path to access only
    # element children.
    # 'NonDocumentTypeChildNode.nextElementSibling',
    'Node.appendChild', # actually not removed, just native implementation.
    'Node.cloneNode',
    'Node.insertBefore',    
    'Node.lastChild',
    'Node.firstChild',
    'Node.parentElement',
    'Node.parentNode',
    'Node.childNodes',
    'Node.removeChild',
    'Node.contains',
    'Node.nextSibling',
    'Node.previousSibling',
    'ChildNode.remove',
    'Document.createTextNode',
    'Window.location',
    'Location.href',
    'Location.hash',
    'Node.querySelector',

    'HTMLElement.hidden',
    'HTMLElement.style',
    'Element.attributes',
    'Window.innerWidth',

    'NodeList.length',
    'NodeList.item',
    'ParentNode.children',
    'ParentNode.firstElementChild',
    'ParentNode.lastElementChild',
    'Event.target',
    'MouseEvent.clientY',
    'MouseEvent.clientX',

    'Node.nodeType',
    'Node.textContent',

    'HTMLCollection.length',
    'HTMLCollection.item',
    'Node.lastElementChild',
    'Node.firstElementChild',
    'HTMLElement_tabIndex',

    'Element.clientWidth',
    'Element.clientHeight',
    'Document.body',
    'Element.removeAttribute',
    'Element.getBoundingClientRect',
    'CSSStyleDeclaration.getPropertyValue',
    'CSSStyleDeclaration.setProperty',
    'CSSStyleDeclaration.__propertyQuery__',

    # TODO(jacobr): consider implementing these methods as well as they show
    # up in benchmarks for some sample applications.
    #'Document.createEvent',
    #'Document.initEvent',
    #'EventTarget.dispatchEvent',
     ])

# Uncomment out this line  to short circuited native methods and run all of
# dart:html through JS interop except for createElement which is slightly more
# tightly natively wired.
# _js_custom_members = Set([])


# Expose built-in methods support by an instance that is not shown in the IDL.
_additional_methods = {
  # Support propertyIsEnumerable (available on all objects only needed by
  # CSSStyleDeclaration decides if style property is supported (handling
  # camelcase and inject hyphens between camelcase).
  # Format of dictionary is 'operation name', arguments, returns value (True or False)
  'CSSStyleDeclaration': ('propertyIsEnumerable', 1, True), 
}


HEADER = """/* Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
 * for details. All rights reserved. Use of this source code is governed by a
 * BSD-style license that can be found in the LICENSE file.
 *
 * DO NOT EDIT
 * Auto-generated _blink library.
 */
library dart.dom._blink;

import 'dart:async';
import 'dart:js' as js;
import 'dart:html' show DomException;
import 'dart:_internal' as internal;
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

  // Below code sets up VMLibraryHooks for resolvePackageUri.
  static Uri resolvePackageUri(Uri packageUri) native "Utils_resolvePackageUri";
  static Future<Uri> _resolvePackageUriFuture(Uri packageUri) async {
      return resolvePackageUri(packageUri);
  }
  static void _setupHooks() {
    internal.VMLibraryHooks.resolvePackageUriFuture = _resolvePackageUriFuture;
  }

  // Defines an interceptor if there is an appropriate JavaScript prototype to define it on.
  // In any case, returns a typed JS wrapper compatible with dart:html and the new
  // typed JS Interop.
  static defineInterceptorCustomElement(jsObject, Type type) native "Utils_defineInterceptorCustomElement";
  static defineInterceptor(jsObject, Type type) native "Utils_defineInterceptor";
  static setInstanceInterceptor(o, Type type, {bool customElement: false}) native "Utils_setInstanceInterceptor";
  static setInstanceInterceptorCustomUpgrade(o) native "Utils_setInstanceInterceptorCustomUpgrade";

  // This method will throw if the element isn't actually a real Element.
  static initializeCustomElement(element) native "Utils_initializeCustomElement";
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
class Stats {
  Stats(this.name) {
    counts = new Map<String, int>();
  }

  String name;
  Map<String, int> counts;
  clear() {
    counts.clear();
  }

  track(String v) {
    counts[v] = counts.putIfAbsent(v, ()=> 0) + 1;
  }
  toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('================');
    sb.write('$name ${counts.length}');
    var keys = counts.keys.toList();
    keys.sort((a,b) => counts[b].compareTo(counts[a]));
    for (var key in keys) {
      print("$key => ${counts[key]}");
    }
    sb.write('---------------');
    sb.write('================');
    return sb;
  }
}

bool TRACK_STATS = true;
dumpStats() {
  print("------------ STATS ----------------");
  print(Blink_JsNative_DomException.getPropertyStats.toString()); 
  print(Blink_JsNative_DomException.setPropertyStats.toString());
  print(Blink_JsNative_DomException.callMethodStats.toString());
  print(Blink_JsNative_DomException.constructorStats.toString());
  print("-----------------------------------");
}

clearStats() {
  Blink_JsNative_DomException.getPropertyStats.clear();
  Blink_JsNative_DomException.setPropertyStats.clear();
  Blink_JsNative_DomException.callMethodStats.clear();  
  Blink_JsNative_DomException.constructorStats.clear();  
}

class Blink_JsNative_DomException {
  static var getPropertyStats = new Stats('get property');
  static var setPropertyStats = new Stats('set property');
  static var callMethodStats = new Stats('call method');
  static var constructorStats = new Stats('constructor');

  static var constructors = new Map<String, dynamic>();

  static getProperty(o, String name) {
    try {
      if (TRACK_STATS) getPropertyStats.track(name);
      return js.JsNative.getProperty(o, name);
    } catch (e) {
      // Re-throw any errors (returned as a string) as a DomException.
      throw new DomException.jsInterop(e);
    }
  }

  static propertyQuery(o, String name) {
    try {
      if (TRACK_STATS) getPropertyStats.track('__propertyQuery__');
      return js.JsNative.getProperty(o, name);
    } catch (e) {
      // Re-throw any errors (returned as a string) as a DomException.
      throw new DomException.jsInterop(e);
    }
  }

  static callConstructor0(String name) {
    try {
      if (TRACK_STATS) constructorStats.track(name);
      var constructor = constructors.putIfAbsent(name, () => js.context[name]);
      return js.JsNative.callConstructor0(constructor);
    } catch (e) {
      // Re-throw any errors (returned as a string) as a DomException.
      throw new DomException.jsInterop(e);
    }
  }

  static callConstructor(String name, List args) {
    try {
      if (TRACK_STATS) constructorStats.track(name);
      var constructor = constructors.putIfAbsent(name, () => js.context[name]);
      return js.JsNative.callConstructor(constructor, args);
    } catch (e) {
      // Re-throw any errors (returned as a string) as a DomException.
      throw new DomException.jsInterop(e);
    }
  }

  static setProperty(o, String name, value) {
    try {
      if (TRACK_STATS) setPropertyStats.track(name);
      return js.JsNative.setProperty(o, name, value);
    } catch (e) {
      // Re-throw any errors (returned as a string) as a DomException.
      throw new DomException.jsInterop(e);
    }
  }

  static callMethod(o, String method, List args) {
    try {
      if (TRACK_STATS) callMethodStats.track(method);
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

#
CONSTRUCTOR_0 = ['  constructorCallback_0_()',
                 ' => Blink_JsNative_DomException.callConstructor0("%s");\n\n',
                 ' native "Blink_Constructor_%s";\n\n']

#(argument_count, arguments, interface_name, arguments)
CONSTRUCTOR_ARGS = ['  constructorCallback_%s_(%s)',
   ' => Blink_JsNative_DomException.callConstructor("%s", [%s]);\n\n',
   ' native "Blink_Constructor_Args_%s" /* %s */;\n\n']

#(attribute_name, attribute_name)
ATTRIBUTE_GETTER = ['  %s_Getter_(mthis)',
                    ' => Blink_JsNative_DomException.getProperty(mthis /* %s */, "%s");\n\n',
                    ' native "Blink_Getter_%s_%s";\n\n'
                    ]

ATTRIBUTE_SETTER = ['  %s_Setter_(mthis, __arg_0)',
                    ' => Blink_JsNative_DomException.setProperty(mthis /* %s */, "%s", __arg_0);\n\n',
                    ' native "Blink_Setter_%s_%s";\n\n'
                    ]

#(operation_name, operationName)
OPERATION_0 = ['  %s_Callback_0_(mthis)',
               ' => Blink_JsNative_DomException.callMethod(mthis /* %s */, "%s", []);\n\n',
               ' native "Blink_Operation_0_%s_%s";\n\n'
               ]

# getter, setter, deleter, propertyQuery code, and propertyIsEnumerable
OPERATION_1 = ['  $%s_Callback_1_(mthis, __arg_0)',
               ' => Blink_JsNative_DomException.callMethod(mthis /* %s */, "%s", [__arg_0]);\n\n',
               ' native "Blink_Operation_1_%s_%s";\n\n'
               ]

OPERATION_2 = ['  $%s_Callback_2_(mthis, __arg_0, __arg_1)',
               ' => Blink_JsNative_DomException.callMethod(mthis /* %s */, "%s", [__arg_0, __arg_1]);\n\n',
               ' native "Blink_Operation_2_%s_%s";\n\n']

OPERATION_PQ = ['  $%s_Callback_1_(mthis, __arg_0)',
                ' => Blink_JsNative_DomException.propertyQuery(mthis, __arg_0); /* %s */ \n\n',
                ' native "Blink_Operation_PQ_%s";\n\n']

#(operation_name, argument_count, arguments, operation_name, arguments)
ARGUMENT_NUM = "__arg_%s"
OPERATION_ARGS = ['  %s_Callback_%s_(mthis, %s)',
                  ' => Blink_JsNative_DomException.callMethod(mthis /* %s */, "%s", [%s]);\n\n',
                  ' native "Blink_Operation_%s_%s"; /* %s */\n\n']



# get class property to make static call.
CLASS_STATIC = 'Blink_JsNative_DomException.getProperty(js.context, "%s")'

# name, classname_getproperty, name
STATIC_ATTRIBUTE_GETTER = ['  %s_Getter_()',
                           ' => Blink_JsNative_DomException.getProperty(%s /* %s */, "%s");\n\n',
                           ' /* %s */ native "Blink_Static_getter_%s_%s"']

# name, classname_getproperty, name
STATIC_OPERATION_0 = ['  %s_Callback_0_()',
                      ' => Blink_JsNative_DomException.callMethod(%s /* %s */, "%s", []);\n\n',
                      ' /* %s */ native "Blink_Static_Operation_0_%s_%s']

# name, argsCount, args, classname_getproperty, name, args
STATIC_OPERATION_ARGS = ['  %s_Callback_%s_(%s)',
                         ' => Blink_JsNative_DomException.callMethod(%s /* %s */, "%s", [%s]);\n\n',
                         ' /* %s */ native "Blink_Static_Operations_%s_%s" /* %s */ \n\n']

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

constructor_renames = {
    'RTCPeerConnection': 'webkitRTCPeerConnection',
    'SpeechRecognition': 'webkitSpeechRecognition',
}

def rename_constructor(name):
  return constructor_renames[name] if name in constructor_renames else name


def _Find_Match(interface_id, member, member_prefix, candidates):
  member_name = interface_id + '.' + member
  if member_name in candidates:
    return member_name
  member_name = interface_id + '.' + member_prefix + member
  if member_name in candidates:
    return member_name
  member_name = interface_id + '.*'
  if member_name in candidates:
    return member_name

def _Is_Native(interface, member):
  return _Find_Match(interface, member, '', _js_custom_members)

def Select_Stub(template, is_native):
  if is_native:
    return template[0] + template[2]
  else:
    return template[0] + template[1]

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
      blink_file.write(Select_Stub(CONSTRUCTOR_0, _Is_Native(name, 'constructor')) % rename_constructor(name))

    _Process_Attributes(blink_file, interface, interface.attributes)
    _Process_Operations(blink_file, interface, interface.operations, True)

    _Emit_Extra_Operations(blink_file, name)

    secondary_parents = database.TransitiveSecondaryParents(interface, False)
    for secondary in secondary_parents:
      _Process_Attributes(blink_file, secondary, secondary.attributes)
      _Process_Operations(blink_file, secondary, secondary.operations, False)

    blink_file.write(CLASS_DEFINITION_END);

  blink_file.write(BLINK_UTILS)

  blink_file.close()

def _Emit_Extra_Operations(blink_file, interface_name):
  if (interface_name in _additional_methods):
    (name, arg_count, return_value) = _additional_methods[interface_name]
    exposed_name = ''.join(['__get', '___', name]) if return_value else name
    blink_file.write(Select_Stub(OPERATION_1, False) % (exposed_name, interface_name, name))

def _Emit_Blink_Constructors(blink_file, analyzed_constructors):
  (arg_min_count, arg_max_count) = generate_parameter_entries(analyzed_constructors.param_infos)
  name = analyzed_constructors.js_name
  if not(name):
    name = analyzed_constructors.type_name

  for callback_index in range(arg_min_count, arg_max_count):
    if callback_index == 0:
      blink_file.write(Select_Stub(CONSTRUCTOR_0, _Is_Native(name, 'constructor')) % (rename_constructor(name)))
    else:
      arguments = []
      for i in range(0, callback_index):
        arguments.append(ARGUMENT_NUM % i)
      argument_list = ', '.join(arguments)
      blink_file.write(
        Select_Stub(CONSTRUCTOR_ARGS, _Is_Native(name, 'constructor')) % (callback_index, argument_list, rename_constructor(name), argument_list))

def _Process_Attributes(blink_file, interface, attributes):
  # Emit an interface's attributes and operations.
  for attribute in sorted(attributes, ConstantOutputOrder):
    name = attribute.id
    is_native = _Is_Native(interface.id, name)
    if attribute.is_read_only:
      if attribute.is_static:
        class_property = CLASS_STATIC % interface.id
        blink_file.write(Select_Stub(STATIC_ATTRIBUTE_GETTER, is_native) % (name, class_property, interface.id, name))
      else:
        blink_file.write(Select_Stub(ATTRIBUTE_GETTER, is_native) % (name, interface.id, name))
    else:
      blink_file.write(Select_Stub(ATTRIBUTE_GETTER, is_native) % (name, interface.id, name))
      blink_file.write(Select_Stub(ATTRIBUTE_SETTER, is_native) % (name, interface.id, name))

def _Process_Operations(blink_file, interface, operations, primary_interface = False):
  analyzeOperations = []

  for operation in sorted(operations, ConstantOutputOrder):
    if len(analyzeOperations) == 0:
      analyzeOperations.append(operation)
    else:
      if analyzeOperations[0].id == operation.id:
        # Handle overloads
        analyzeOperations.append(operation)
      else:
        _Emit_Blink_Operation(blink_file, interface, analyzeOperations, primary_interface)
        analyzeOperations = [operation]
  if len(analyzeOperations) > 0:
    _Emit_Blink_Operation(blink_file, interface, analyzeOperations, primary_interface)

# List of DartName operations to not emit (e.g., For now only WebGL2RenderingContextBase
# has readPixels in both WebGLRenderingContextBase and WebGL2RenderingContextBase.
# Furthermore, readPixels has the exact same number of arguments - in Javascript
# there is no typing so they're the same.
suppressed_operations = {
    'WebGL2RenderingContextBase': [ 'readPixels2', 'texImage2D2' ],
}

def _Suppress_Secondary_Interface_Operation(interface, analyzed):
  if interface.id in suppressed_operations:
    # Should this DartName (name property) be suppressed on this interface?
    return analyzed.name in suppressed_operations[interface.id]
  return False

def _Emit_Blink_Operation(blink_file, interface, analyzeOperations, primary_interface):
  analyzed = AnalyzeOperation(interface, analyzeOperations)

  if not(primary_interface) and _Suppress_Secondary_Interface_Operation(interface, analyzed):
    return

  (arg_min_count, arg_max_count) = generate_parameter_entries(analyzed.param_infos)
  name = analyzed.js_name

  is_native = _Is_Native(interface.id, name)

  operation = analyzeOperations[0]
  if (name.startswith('__') and \
      ('getter' in operation.specials or \
       'setter' in operation.specials or \
       'deleter' in operation.specials)):
    if name == '__propertyQuery__':
      blink_file.write(Select_Stub(OPERATION_PQ, is_native) % (name, interface.id))
    else:
      arg_min_count = arg_max_count
      if arg_max_count == 2:
        blink_file.write(Select_Stub(OPERATION_1, is_native) % (name, interface.id, name))
      elif arg_max_count == 3:
        blink_file.write(Select_Stub(OPERATION_2, is_native) % (name, interface.id, name))
      else:
        print "FATAL ERROR: _blink emitter operator %s.%s" % (interface.id, name)
        exit

    return

  for callback_index in range(arg_min_count, arg_max_count):
    if callback_index == 0:
      if operation.is_static:
        class_property = CLASS_STATIC % interface.id
        blink_file.write(Select_Stub(STATIC_OPERATION_0, is_native) % (name, class_property, interface.id, name))
      else:
        blink_file.write(Select_Stub(OPERATION_0, is_native) % (name, interface.id, name))
    else:
      arguments = []
      for i in range(0, callback_index):
        arguments.append(ARGUMENT_NUM % i)
      argument_list = ', '.join(arguments)
      if operation.is_static:
        class_property = CLASS_STATIC % interface.id
        blink_file.write(Select_Stub(STATIC_OPERATION_ARGS, is_native) % (name, callback_index, argument_list, class_property, interface.id, name, argument_list))
      else:
        blink_file.write(Select_Stub(OPERATION_ARGS, is_native) % (name, callback_index, argument_list, interface.id, name, argument_list))
