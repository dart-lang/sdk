// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_string';
import 'dart:_wasm';

@pragma("wasm:prefer-inline")
void _invokeMainArg0(List<String> args, Function() mainMethod) {
  mainMethod();
  return;
}

@pragma("wasm:prefer-inline")
void _invokeMainArg1(List<String> args, Function(List<String>) mainMethod) {
  mainMethod(args);
  return;
}

@pragma("wasm:prefer-inline")
void _invokeMainArg2(
  List<String> args,
  Function(List<String>, Null) mainMethod,
) {
  mainMethod(args, null);
  return;
}

// Will be patched in `pkg/dart2wasm/lib/compile.dart` right before TFA.
external void _invokeMainInternal(List<String> args);

/// Used to invoke the `main` function from JS, printing any exceptions that
/// escape.
@pragma("wasm:export", "\$invokeMain")
WasmVoid _invokeMain(WasmArray<WasmExternRef?> args) {
  try {
    final dartArgs = <String>[];
    for (var i = 0; i < args.length; i++) {
      dartArgs.add(JSStringImpl.fromRefUnchecked(args[i]));
    }

    _invokeMainInternal(dartArgs);
    return WasmVoid();
  } catch (e, s) {
    print(e);
    print(s);
    rethrow;
  }
}
