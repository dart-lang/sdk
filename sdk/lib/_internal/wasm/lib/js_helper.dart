// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Helpers for working with JS.
library dart.js_helper;

import 'dart:_internal';
import 'dart:wasm';

/// [JSValue] is the root of the JS interop object hierarchy.
class JSValue {
  final WasmAnyRef _ref;

  JSValue(this._ref);

  static JSValue? box(WasmAnyRef? ref) => ref == null ? null : JSValue(ref);

  WasmAnyRef toAnyRef() => _ref;
  String toString() => jsStringToDartString(_ref);
  List<Object?> toObjectList() => toDartList(_ref);
  Object toObject() => jsObjectToDartObject(_ref);
}

extension StringToJS on String {
  JSValue toJS() => JSValue(jsStringFromDartString(this));
}

extension ListOfObjectToJS on List<Object?> {
  JSValue toJS() => JSValue(jsArrayFromDartList(this));
}

extension ObjectToJS on Object {
  JSValue toJS() => JSValue(jsObjectFromDartObject(this));
}

Object jsObjectToDartObject(WasmAnyRef ref) => unsafeCastOpaque<Object>(ref);

WasmAnyRef jsObjectFromDartObject(Object object) =>
    unsafeCastOpaque<WasmAnyRef>(object);

@pragma("wasm:import", "dart2wasm.isJSUndefined")
external bool isJSUndefined(WasmAnyRef? o);

@pragma("wasm:import", "dart2wasm.isJSBoolean")
external bool isJSBoolean(WasmAnyRef? o);

@pragma("wasm:import", "dart2wasm.isJSNumber")
external bool isJSNumber(WasmAnyRef? o);

@pragma("wasm:import", "dart2wasm.isJSBigInt")
external bool isJSBigInt(WasmAnyRef? o);

@pragma("wasm:import", "dart2wasm.isJSString")
external bool isJSString(WasmAnyRef? o);

@pragma("wasm:import", "dart2wasm.isJSSymbol")
external bool isJSSymbol(WasmAnyRef? o);

@pragma("wasm:import", "dart2wasm.isJSFunction")
external bool isJSFunction(WasmAnyRef? o);

@pragma("wasm:import", "dart2wasm.isJSArray")
external bool isJSArray(WasmAnyRef? o);

@pragma("wasm:import", "dart2wasm.isJSWrappedDartFunction")
external bool isJSWrappedDartFunction(WasmAnyRef? o);

@pragma("wasm:import", "dart2wasm.isJSObject")
external bool isJSObject(WasmAnyRef? o);

@pragma("wasm:import", "dart2wasm.roundtrip")
external double toDartNumber(WasmAnyRef ref);

@pragma("wasm:import", "dart2wasm.roundtrip")
external bool toDartBool(WasmAnyRef ref);

@pragma("wasm:import", "dart2wasm.objectLength")
external double objectLength(WasmAnyRef ref);

@pragma("wasm:import", "dart2wasm.objectReadIndex")
external WasmAnyRef? objectReadIndex(WasmAnyRef ref, int index);

@pragma("wasm:import", "dart2wasm.unwrapJSWrappedDartFunction")
external Object? unwrapJSWrappedDartFunction(WasmAnyRef f);

@pragma("wasm:import", "dart2wasm.arrayFromDartList")
external WasmAnyRef jsArrayFromDartList(List<Object?> list);

@pragma("wasm:import", "dart2wasm.stringFromDartString")
external WasmAnyRef jsStringFromDartString(String string);

@pragma("wasm:import", "dart2wasm.stringToDartString")
external String jsStringToDartString(WasmAnyRef string);

@pragma("wasm:import", "dart2wasm.eval")
external void evalRaw(WasmAnyRef code);

@pragma("wasm:import", "dart2wasm.newObject")
external WasmAnyRef newObjectRaw();

@pragma("wasm:import", "dart2wasm.globalThis")
external WasmAnyRef globalThisRaw();

@pragma("wasm:import", "dart2wasm.callConstructorVarArgs")
external WasmAnyRef callConstructorVarArgsRaw(WasmAnyRef o, WasmAnyRef args);

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

// Currently, `allowInterop` returns a Function type. This is unfortunate for
// Dart2wasm because it means arbitrary Dart functions can flow to JS util
// calls. Our only solutions is to cache every function called with
// `allowInterop` and to replace them with the wrapped variant when they flow
// to JS.
// NOTE: We are not currently replacing functions returned from JS.
Map<Function, JSValue> functionToJSWrapper = {};

WasmAnyRef? jsifyRaw(Object? object) {
  if (object == null) {
    return null;
  } else if (object is Function) {
    assert(functionToJSWrapper.containsKey(object),
        'Must call `allowInterop` on functions before they flow to JS');
    return functionToJSWrapper[object]?.toAnyRef();
  } else if (object is JSValue) {
    return object.toAnyRef();
  } else if (object is String) {
    return jsStringFromDartString(object);
  } else if (object is List<Object?>) {
    return jsArrayFromDartList(object);
  } else {
    return jsObjectFromDartObject(object);
  }
}

/// TODO(joshualitt): We shouldn't need this, but otherwise we seem to get a
/// cast error for certain oddball types(I think undefined, but need to dig
/// deeper).
@pragma("wasm:export", "\$dartifyRaw")
Object? dartifyExported(WasmAnyRef? ref) => dartifyRaw(ref);

Object? dartifyRaw(WasmAnyRef? ref) {
  if (ref == null) {
    return null;
  } else if (isJSUndefined(ref)) {
    // TODO(joshualitt): Introduce a `JSUndefined` type.
    return null;
  } else if (isJSBoolean(ref)) {
    return toDartBool(ref);
  } else if (isJSNumber(ref)) {
    return toDartNumber(ref);
  } else if (isJSString(ref)) {
    return jsStringToDartString(ref);
  } else if (isJSArray(ref)) {
    return toDartList(ref);
  } else if (isJSWrappedDartFunction(ref)) {
    return unwrapJSWrappedDartFunction(ref);
  } else if (isJSObject(ref) ||
      // TODO(joshualitt): We may want to create proxy types for some of these
      // cases.
      isJSBigInt(ref) ||
      isJSSymbol(ref) ||
      isJSFunction(ref)) {
    return JSValue(ref);
  } else {
    return jsObjectToDartObject(ref);
  }
}

List<Object?> toDartList(WasmAnyRef ref) => List<Object?>.generate(
    objectLength(ref).round(), (int n) => dartifyRaw(objectReadIndex(ref, n)));

@pragma("wasm:import", "dart2wasm.wrapDartFunction")
external WasmAnyRef _wrapDartFunctionRaw(
    WasmAnyRef dartFunction, WasmAnyRef trampolineName);

F _wrapDartFunction<F extends Function>(F f, String trampolineName) {
  if (functionToJSWrapper.containsKey(f)) {
    return f;
  }
  JSValue wrappedFunction = JSValue(_wrapDartFunctionRaw(
      f.toJS().toAnyRef(), trampolineName.toJS().toAnyRef()));
  functionToJSWrapper[f] = wrappedFunction;
  return f;
}

/// Methods used by the wasm runtime.
@pragma("wasm:export", "\$listLength")
double _listLength(List list) => list.length.toDouble();

@pragma("wasm:export", "\$listRead")
WasmAnyRef? _listRead(List<Object?> list, double index) =>
    jsifyRaw(list[index.toInt()]);
