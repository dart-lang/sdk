// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart.js_util_wasm;

import "dart:_internal";
import "dart:js_util_wasm";
import "dart:wasm";

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

@patch
Object _jsObjectToDartObject(WasmAnyRef ref) => unsafeCastOpaque<Object>(ref);

@patch
WasmAnyRef _jsObjectFromDartObject(Object object) =>
    unsafeCastOpaque<WasmAnyRef>(object);

@patch
JSValue allowInterop<F extends Function>(F f) => throw 'unreachable';
