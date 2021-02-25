// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import 'dylib_utils.dart';

import "package:expect/expect.dart";

final ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");

typedef NativeCallbackTest = Int32 Function(Pointer);
typedef NativeCallbackTestFn = int Function(Pointer);

class CallbackTest {
  final String name;
  final Pointer callback;
  final void Function() afterCallbackChecks;

  CallbackTest(this.name, this.callback) : afterCallbackChecks = noChecks {}
  CallbackTest.withCheck(this.name, this.callback, this.afterCallbackChecks) {}

  void run() {
    final NativeCallbackTestFn tester = ffiTestFunctions
        .lookupFunction<NativeCallbackTest, NativeCallbackTestFn>("Test$name");

    final int testCode = tester(callback);

    if (testCode != 0) {
      Expect.fail("Test $name failed.");
    }

    afterCallbackChecks();
  }
}

void noChecks() {}
