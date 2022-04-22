// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Prototype js util library for wasm.
library dart.js_util_wasm;

import 'dart:wasm';

/// [JSValue] is the root of the JS interop object hierarchy.
class JSValue {
  final WasmAnyRef _ref;

  JSValue(this._ref);

  static JSValue? box(WasmAnyRef? ref) => ref == null ? null : JSValue(ref);

  WasmAnyRef toAnyRef() => _ref;
  String toString() => _jsStringToDartString(_ref);
  List<Object?> toObjectList() => _jsArrayToDartList(_ref);
  Object toObject() => _jsObjectToDartObject(_ref);
}

/// Raw private JS functions.
external WasmAnyRef _jsObjectFromDartObject(Object object);

external Object _jsObjectToDartObject(WasmAnyRef ref);

@pragma("wasm:import", "dart2wasm.arrayFromDartList")
external WasmAnyRef _jsArrayFromDartList(List<Object?> list);

@pragma("wasm:import", "dart2wasm.arrayToDartList")
external List<Object?> _jsArrayToDartList(WasmAnyRef list);

@pragma("wasm:import", "dart2wasm.stringFromDartString")
external WasmAnyRef _jsStringFromDartString(String string);

@pragma("wasm:import", "dart2wasm.stringToDartString")
external String _jsStringToDartString(WasmAnyRef string);

@pragma("wasm:import", "dart2wasm.wrapDartCallback")
external WasmAnyRef _wrapDartCallbackRaw(
    WasmAnyRef callback, WasmAnyRef trampolineName);

JSValue? _wrapDartCallback(Object callback, String trampolineName) {
  return JSValue(_wrapDartCallbackRaw(
      callback.toJS().toAnyRef(), trampolineName.toJS().toAnyRef()));
}

/// Raw public JS functions.
/// These are public temporarily to give performance conscious users an escape
/// hatch while we decide what this API will actually look like. They may
/// become private in the future, or disappear entirely. For descriptions of the
/// API, please see the corresponding non-raw functions.
@pragma("wasm:import", "dart2wasm.eval")
external void evalRaw(WasmAnyRef code);

@pragma("wasm:import", "dart2wasm.dartify")
external WasmAnyRef? dartifyRaw(WasmAnyRef? object);

@pragma("wasm:import", "dart2wasm.newObject")
external WasmAnyRef newObjectRaw();

@pragma("wasm:import", "dart2wasm.globalThis")
external WasmAnyRef globalThisRaw();

@pragma("wasm:import", "dart2wasm.callConstructorVarArgs")
external WasmAnyRef callConstructorVarArgsRaw(
    WasmAnyRef o, WasmAnyRef name, WasmAnyRef args);

@pragma("wasm:import", "dart2wasm.hasProperty")
external bool hasPropertyRaw(WasmAnyRef o, WasmAnyRef name);

@pragma("wasm:import", "dart2wasm.getProperty")
external WasmAnyRef? getPropertyRaw(WasmAnyRef o, WasmAnyRef name);

@pragma("wasm:import", "dart2wasm.setProperty")
external WasmAnyRef? setPropertyRaw(
    WasmAnyRef o, WasmAnyRef name, WasmAnyRef? value);

@pragma("wasm:import", "dart2wasm.callMethodVarArgs")
external WasmAnyRef? callMethodVarArgsRaw(
    WasmAnyRef o, WasmAnyRef method, WasmAnyRef? args);

WasmAnyRef? jsifyRaw(Object? object) {
  if (object == null) {
    return null;
  } else if (object is JSValue) {
    return object.toAnyRef();
  } else if (object is String) {
    return _jsStringFromDartString(object);
  } else if (object is List<Object?>) {
    return _jsArrayFromDartList(object);
  } else {
    return _jsObjectFromDartObject(object);
  }
}

/// Conversion functions.
/// TODO(joshualitt): Only a small set of types currently work:
///   JS -> Dart:
///     null
///     strings
///     arrays
///     opaque Dart objects passed to JS
///   Dart -> JS:
///     null
///     boolean
///     doubles
///     strings
///     lists
///     opaque JS objects passed to Dart
/// In the future we would like to support more types, at least maps,
/// and to fix some of the issues returning some types from JS.

/// Extension methods for conversions.
extension StringToJS on String {
  JSValue toJS() => JSValue(_jsStringFromDartString(this));
}

extension ListOfObjectToJS on List<Object?> {
  JSValue toJS() => JSValue(_jsArrayFromDartList(this));
}

extension ObjectToJS on Object {
  JSValue toJS() => JSValue(_jsObjectFromDartObject(this));
}

/// Recursively converts objects from Dart to JS.
JSValue? jsify(Object? object) => JSValue.box(jsifyRaw(object));

/// Recursively converts objects from JS to Dart.
Object? dartify(JSValue? object) => object == null
    ? null
    : _jsObjectToDartObject(dartifyRaw(object.toAnyRef())!);

/// js util methods.
/// These are low level calls into JS, and require care to use correctly.

/// Evals a snippet of JS code in a Dart string.
void eval(String code) => evalRaw(code.toJS().toAnyRef());

/// Creates a new JS object literal and returns it.
JSValue newObject() => JSValue(newObjectRaw());

/// Returns a reference to `globalThis`.
JSValue globalThis() => JSValue(globalThisRaw());

/// Gets a [String] name property off of a JS object [o], invokes it as
/// a constructor with a JS array of arguments [args], and returns the
/// constructed JS object.
JSValue callConstructorVarArgs(JSValue o, String name, List<JSValue?> args) =>
    JSValue(callConstructorVarArgsRaw(
        o.toAnyRef(), name.toJS().toAnyRef(), args.toJS().toAnyRef()));

/// Checks for a [String] name on a JS object [o].
bool hasProperty(JSValue o, String name) =>
    hasPropertyRaw(o.toAnyRef(), name.toJS().toAnyRef());

/// Gets a JS property with [String] name off of a JS object [o].
JSValue? getProperty(JSValue o, String name) =>
    JSValue.box(getPropertyRaw(o.toAnyRef(), name.toJS().toAnyRef()));

/// Sets a JS property with [String] name on JS object [o] to the JS value
/// [value], then returns [value].
JSValue? setProperty(JSValue o, String name, JSValue? value) => JSValue.box(
    setPropertyRaw(o.toAnyRef(), name.toJS().toAnyRef(), value?.toAnyRef()));

/// Calls a JS method with a [String] name on JS object [o] with a JS array
/// of arguments [args] and returns the resulting JS value.
JSValue? callMethodVarArgs(JSValue o, String method, List<JSValue?> args) =>
    JSValue.box(callMethodVarArgsRaw(
        o.toAnyRef(), method.toJS().toAnyRef(), args.toJS().toAnyRef()));

/// Returns a wrapped version of [f] suitable for calling from JS. Use [dartify]
/// to convert back to Dart.
/// TODO(joshualitt): This is significantly different from the implementation of
/// [allowInterop] on other web backends. We will need to come up with a unified
/// semantics or Dart programs will not be able to work correctly across
/// different web backends.
external JSValue allowInterop<F extends Function>(F f);
