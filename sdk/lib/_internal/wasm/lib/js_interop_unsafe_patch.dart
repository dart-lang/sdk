// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart.js_interop_unsafe;

import 'dart:_internal' show patch;
import "dart:_js_helper";
import 'dart:_wasm';
import 'dart:js_interop' hide JS;

/// TODO(joshualitt): When `JSNull` and `JSUndefined` are boxed we can share
/// this with `js_interop_patch.dart`.
T _box<T>(WasmExternRef? ref) => JSValue.box(ref) as T;

@patch
extension JSObjectUtilExtension on JSObject {
  @patch
  JSBoolean hasProperty(JSAny property) => _box<JSBoolean>(JS<WasmExternRef?>(
      '(o, p) => p in o', toExternRef, property.toExternRef));

  @patch
  JSAny? operator [](JSAny property) => _box<JSAny?>(
      JS<WasmExternRef?>('(o, p) => o[p]', toExternRef, property.toExternRef));

  @patch
  void operator []=(JSAny property, JSAny? value) => JS<void>(
      '(o, p, v) => o[p] = v',
      toExternRef,
      property.toExternRef,
      value?.toExternRef);

  // TODO(joshualitt): Consider specializing variadic functions.
  @patch
  JSAny? _callMethod(JSAny method,
          [JSAny? arg1, JSAny? arg2, JSAny? arg3, JSAny? arg4]) =>
      _box<JSAny?>(callMethodVarArgsRaw(
          toExternRef,
          method.toExternRef,
          arg1 == null
              ? null
              : [
                  arg1,
                  if (arg2 != null) arg2,
                  if (arg3 != null) arg3,
                  if (arg4 != null) arg4,
                ].toExternRef));

  @patch
  JSAny? _callMethodVarArgs(JSAny method, [List<JSAny?>? arguments]) =>
      _box<JSAny?>(callMethodVarArgsRaw(
          toExternRef, method.toExternRef, arguments?.toExternRef));

  @patch
  JSBoolean delete(JSAny property) => _box<JSBoolean>(JS<WasmExternRef?>(
      '(o, p) => delete o[p]', toExternRef, property.toExternRef));
}

@patch
extension JSFunctionUtilExtension on JSFunction {
  @patch
  JSObject _callAsConstructor(
          [JSAny? arg1, JSAny? arg2, JSAny? arg3, JSAny? arg4]) =>
      _box<JSObject>(callConstructorVarArgsRaw(
          toExternRef,
          arg1 == null
              ? null
              : [
                  arg1,
                  if (arg2 != null) arg2,
                  if (arg3 != null) arg3,
                  if (arg4 != null) arg4,
                ].toExternRef));

  @patch
  JSObject _callAsConstructorVarArgs([List<JSAny?>? arguments]) =>
      _box<JSObject>(
          callConstructorVarArgsRaw(toExternRef, arguments?.toExternRef));
}
