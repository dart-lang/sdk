// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import 'dylib_utils.dart';

import "package:expect/expect.dart";

final ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");

typedef NativeAsyncCallbackTest = Void Function(Pointer);
typedef NativeAsyncCallbackTestFn = void Function(Pointer);

class AsyncCallbackTest {
  final String name;
  final Future<void> Function() afterCallbackChecks;

  // Either a NativeCallable or a Pointer.fromFunction.
  final Object callback;

  AsyncCallbackTest(this.name, this.callback, this.afterCallbackChecks) {}

  Future<void> run() async {
    final NativeAsyncCallbackTestFn tester = ffiTestFunctions.lookupFunction<
        NativeAsyncCallbackTest, NativeAsyncCallbackTestFn>("TestAsync$name");

    final cb = callback;
    tester(cb is NativeCallable ? cb.nativeFunction : cb as Pointer);

    await afterCallbackChecks();
    if (cb is NativeCallable) {
      cb.close();
    }
  }
}

void noChecks() {}
