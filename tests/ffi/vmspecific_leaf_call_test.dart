// Copyright (c) 2021, the Dart project authors.
// Please see the AUTHORS file for details. 
// All rights reserved. Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.
//
// SharedObjects=ffi_test_functions

// Formatting can break multitests, so don't format them.
// dart format off

import 'dart:ffi';
import 'dart:io';

import 'package:expect/expect.dart';

import 'callback_tests_utils.dart';
import 'dylib_utils.dart';

DynamicLibrary ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");

void testLeafCall() {
  // Regular calls should transition from generated Dart code to native.
  final isThreadInGenerated = ffiTestFunctions
      .lookupFunction<Int8 Function(), int Function()>("IsThreadInGenerated");

  Expect.equals(0, isThreadInGenerated());

  // Leaf calls should remain in generated state.
  final isThreadInGeneratedLeaf = ffiTestFunctions.lookupFunction<
      Int8 Function(),
      int Function()>("IsThreadInGenerated", isLeaf: true);

  Expect.equals(1, isThreadInGeneratedLeaf());
}

void testLeafCallApi() {
  // In debug mode, this should crash due to unsafe use of Dart APIs.
  final f = ffiTestFunctions.lookupFunction<Void Function(), void Function()>(
      "TestLeafCallApi",
      isLeaf: true);

  // Unsafe: Calling Dart API from a leaf function.
  f();
}

void nop() {}

void testCallbackLeaf() {
  // This test should fail with "expected: T->IsAtSafepoint()".
  // Callbacks from leaf calls are not allowed.
  CallbackTest("CallbackLeaf", Pointer.fromFunction<Void Function()>(nop),
          isLeaf: true)
      .run();
}

void main() {
  testLeafCall();

  // These tests cause process termination on success.
  if (Platform.isLinux && !const bool.fromEnvironment("dart.vm.product")) {
    testLeafCallApi();
    testCallbackLeaf();
  }
}
