// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// SharedObjects=ffi_test_functions

import 'dart:ffi';
import 'dart:io';

import 'package:expect/expect.dart';

import 'callback_tests_utils.dart';
import 'dylib_utils.dart';

DynamicLibrary ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");

testLeafCall() {
  // Regular calls should transition generated -> native.
  final isThreadInGenerated = ffiTestFunctions
      .lookupFunction<Int8 Function(), int Function()>("IsThreadInGenerated");
  Expect.equals(0, isThreadInGenerated());
  // Leaf calls should remain in generated state.
  final isThreadInGeneratedLeaf = ffiTestFunctions
      .lookupFunction<Int8 Function(), int Function()>("IsThreadInGenerated",
          isLeaf: true);
  Expect.equals(1, isThreadInGeneratedLeaf());
}

testLeafCallApi() {
  // Note: This will only crash as expected in debug build mode. In other modes
  // it's effectively skip.
  final f = ffiTestFunctions.lookupFunction<Void Function(), void Function()>(
      "TestLeafCallApi",
      isLeaf: true);
  // Calling Dart_.. API is unsafe from leaf calls since we explicitly haven't
  // made the generated -> native transition.
  f();
}

void nop() {}

testCallbackLeaf() {
  // This should crash with "expected: T->IsAtSafepoint()", since it's unsafe to
  // do callbacks from leaf calls (otherwise they wouldn't be leaf calls).
  // Note: This will only crash as expected in debug build mode. In other modes
  // it's effectively skip.
  CallbackTest("CallbackLeaf", Pointer.fromFunction<Void Function()>(nop),
          isLeaf: true)
      .run();
}

main() {
  testLeafCall(); //# 01: ok
  // These tests terminate the process after successful completion, so we have
  // to run them separately.
  //
  // Since they use signal handlers they only run on Linux.
  if (Platform.isLinux && !const bool.fromEnvironment("dart.vm.product")) {
    testLeafCallApi(); //# 02: ok
    testCallbackLeaf(); //# 03: ok
  }
}
