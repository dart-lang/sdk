// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop'
    show JSArray, JSArrayToList, JSString, JSStringToString;
import 'dart:_js_helper' show JSValue;
import 'dart:_wasm';

@pragma("wasm:prefer-inline")
void _invokeMainArg0(WasmExternRef jsArrayRef, Function() mainMethod) {
  mainMethod();
  return;
}

@pragma("wasm:prefer-inline")
void _invokeMainArg1(
  WasmExternRef jsArrayRef,
  Function(List<String>) mainMethod,
) {
  final jsArray = (JSValue(jsArrayRef) as JSArray<JSString>).toDart;
  final args = <String>[for (final jsValue in jsArray) jsValue.toDart];
  mainMethod(List.unmodifiable(args));
  return;
}

@pragma("wasm:prefer-inline")
void _invokeMainArg2(
  WasmExternRef jsArrayRef,
  Function(List<String>, Null) mainMethod,
) {
  final jsArray = (JSValue(jsArrayRef) as JSArray<JSString>).toDart;
  final args = <String>[for (final jsValue in jsArray) jsValue.toDart];
  mainMethod(List.unmodifiable(args), null);
  return;
}

// Will be patched in `pkg/dart2wasm/lib/compile.dart` right before TFA.
external void _invokeMainInternal(WasmExternRef jsArray);

/// Used to invoke the `main` function from JS, printing any exceptions that
/// escape.
@pragma("wasm:export", "\$invokeMain")
void _invokeMain(WasmExternRef jsArrayRef) {
  try {
    _invokeMainInternal(jsArrayRef);
  } catch (e, s) {
    print(e);
    print(s);
    rethrow;
  }
}
