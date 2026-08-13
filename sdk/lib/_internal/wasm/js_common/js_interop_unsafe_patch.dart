// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart.js_interop_unsafe;

import 'dart:_internal' show patch;
import "dart:_js_helper";
import 'dart:_wasm';
import 'dart:js_interop' hide JS;

@patch
extension JSObjectUnsafeUtilExtension on JSObject {
  @patch
  JSBoolean hasProperty(JSAny property) => JSValue.boxT<JSBoolean>(
    JS<WasmExternRef?>('(o, p) => p in o', toExternRef, property.toExternRef),
  );

  @patch
  T getProperty<T extends JSAny?>(JSAny property) => JSValue.boxT<T>(
    JS<WasmExternRef?>('(o, p) => o[p]', toExternRef, property.toExternRef),
  );

  @patch
  void setProperty(JSAny property, JSAny? value) => JS<void>(
    '(o, p, v) => o[p] = v',
    toExternRef,
    property.toExternRef,
    value.toExternRef,
  );

  @patch
  JSAny? _callMethod(
    JSAny method, [
    JSAny? arg1,
    JSAny? arg2,
    JSAny? arg3,
    JSAny? arg4,
  ]) => JSValue.boxT<JSAny?>(
    callMethodVarArgsRaw(
      toExternRef,
      method.toExternRef,
      [
        if (arg1 != null) arg1,
        if (arg2 != null) arg2,
        if (arg3 != null) arg3,
        if (arg4 != null) arg4,
      ].toJS.toExternRef,
    ),
  );

  @patch
  JSAny? _callMethodVarArgs(JSAny method, [List<JSAny?>? arguments]) =>
      JSValue.boxT<JSAny?>(
        callMethodVarArgsRaw(
          toExternRef,
          method.toExternRef,
          (arguments ?? <JSAny?>[]).toJS.toExternRef,
        ),
      );

  @patch
  JSBoolean delete(JSAny property) => JSValue.boxT<JSBoolean>(
    JS<WasmExternRef?>(
      '(o, p) => delete o[p]',
      toExternRef,
      property.toExternRef,
    ),
  );
}

@patch
extension JSFunctionUnsafeUtilExtension on JSFunction {
  @patch
  JSObject _callAsConstructor([
    JSAny? arg1,
    JSAny? arg2,
    JSAny? arg3,
    JSAny? arg4,
  ]) => JSValue.boxT<JSObject>(
    callConstructorVarArgsRaw(
      toExternRef,
      [
        if (arg1 != null) arg1,
        if (arg2 != null) arg2,
        if (arg3 != null) arg3,
        if (arg4 != null) arg4,
      ].toJS.toExternRef,
    ),
  );

  @patch
  JSObject _callAsConstructorVarArgs([List<JSAny?>? arguments]) =>
      JSValue.boxT<JSObject>(
        callConstructorVarArgsRaw(
          toExternRef,
          (arguments ?? <JSAny?>[]).toJS.toExternRef,
        ),
      );
}
