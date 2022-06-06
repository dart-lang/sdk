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
  List<Object?> toObjectList() => jsArrayToDartList(_ref);
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

Object? toDart(WasmAnyRef? ref) {
  if (ref == null) {
    return null;
  }
  return jsObjectToDartObject(dartifyRaw(ref)!);
}

Object jsObjectToDartObject(WasmAnyRef ref) => unsafeCastOpaque<Object>(ref);

WasmAnyRef jsObjectFromDartObject(Object object) =>
    unsafeCastOpaque<WasmAnyRef>(object);

@pragma("wasm:import", "dart2wasm.arrayFromDartList")
external WasmAnyRef jsArrayFromDartList(List<Object?> list);

@pragma("wasm:import", "dart2wasm.arrayToDartList")
external List<Object?> jsArrayToDartList(WasmAnyRef list);

@pragma("wasm:import", "dart2wasm.stringFromDartString")
external WasmAnyRef jsStringFromDartString(String string);

@pragma("wasm:import", "dart2wasm.stringToDartString")
external String jsStringToDartString(WasmAnyRef string);

@pragma("wasm:import", "dart2wasm.eval")
external void evalRaw(WasmAnyRef code);

@pragma("wasm:import", "dart2wasm.dartify")
external WasmAnyRef? dartifyRaw(WasmAnyRef? object);

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

WasmAnyRef? jsifyRaw(Object? object) {
  if (object == null) {
    return null;
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

/// js_util_wasm methods used by the wasm runtime.
@pragma("wasm:export", "\$listLength")
double _listLength(List list) => list.length.toDouble();

@pragma("wasm:export", "\$listRead")
WasmAnyRef? _listRead(List<Object?> list, double index) =>
    jsifyRaw(list[index.toInt()]);

@pragma("wasm:export", "\$listAllocate")
List<Object?> _listAllocate() => [];

@pragma("wasm:export", "\$listAdd")
void _listAdd(List<Object?> list, WasmAnyRef? item) =>
    list.add(dartifyRaw(item));

@pragma("wasm:export", "\$boxJSValue")
JSValue _boxJSValue(WasmAnyRef ref) => JSValue(ref);
