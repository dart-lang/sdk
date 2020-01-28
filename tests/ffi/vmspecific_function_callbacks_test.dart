// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-testing-pragmas --enable-isolate-groups
// VMOptions=--enable-testing-pragmas --no-enable-isolate-groups
//
// Dart test program for testing dart:ffi function pointers with callbacks.
//
// VMOptions=--enable-testing-pragmas
// VMOptions=--enable-testing-pragmas --stacktrace-every=100
// VMOptions=--enable-testing-pragmas --write-protect-code --no-dual-map-code
// VMOptions=--enable-testing-pragmas --write-protect-code --no-dual-map-code --stacktrace-every=100
// VMOptions=--use-slow-path --enable-testing-pragmas
// VMOptions=--use-slow-path --enable-testing-pragmas --stacktrace-every=100
// VMOptions=--use-slow-path --enable-testing-pragmas --write-protect-code --no-dual-map-code
// VMOptions=--use-slow-path --enable-testing-pragmas --write-protect-code --no-dual-map-code --stacktrace-every=100
// SharedObjects=ffi_test_functions

import 'dart:ffi';

import 'ffi_test_helpers.dart';
import 'callback_tests_utils.dart';
import 'dylib_utils.dart';

typedef ReturnVoid = Void Function();

final testLibrary = dlopenPlatformSpecific("ffi_test_functions");

void testGC() {
  triggerGc();
}

typedef WaitForHelperNative = Void Function(Pointer<Void>);
typedef WaitForHelper = void Function(Pointer<Void>);

void waitForHelper(Pointer<Void> helper) {
  print("helper: $helper");
  testLibrary.lookupFunction<WaitForHelperNative, WaitForHelper>(
      "WaitForHelper")(helper);
}

final testcases = [
  CallbackTest("GC", Pointer.fromFunction<ReturnVoid>(testGC)),
  CallbackTest("UnprotectCode",
      Pointer.fromFunction<WaitForHelperNative>(waitForHelper)),
];

const double zeroPointZero = 0.0;

// Correct type of exceptionalReturn argument to Pointer.fromFunction.
double testExceptionalReturn() {
  Pointer.fromFunction<Double Function()>(testExceptionalReturn, 0.0);
  Pointer.fromFunction<Double Function()>(testExceptionalReturn, zeroPointZero);

  return 0.0;
}

void main() {
  testExceptionalReturn();

  testcases.forEach((t) => t.run());
}
