// Copyright (c) 2019, the Dart project authors.  
// Please see the AUTHORS file for details.  
// All rights reserved. Use of this source code is governed by a  
// BSD-style license that can be found in the LICENSE file.  
//
// Dart test program for testing dart:ffi function pointers with callbacks.
//
// VMOptions=
// VMOptions=--use-slow-path
// SharedObjects=ffi_test_functions

import 'dart:io';
import 'dart:ffi';
import 'dart:isolate';

// Formatting can break multitests, so don't format them.
// dart format off

import "package:expect/expect.dart";
import 'callback_tests_utils.dart';
import 'dylib_utils.dart';

final DynamicLibrary testLibrary = dlopenPlatformSpecific("ffi_test_functions");

typedef ReturnVoid = Void Function();
typedef NativeCallbackTest = Int32 Function(Pointer<Void>);
typedef NativeCallbackTestFn = int Function(Pointer<Void>);

void returnVoid() {}

void testCallbackWrongThread() {
  print("Test CallbackWrongThread.");
  CallbackTest(
          "CallbackWrongThread", Pointer.fromFunction<ReturnVoid>(returnVoid))
      .run();
}

void testCallbackOutsideIsolate() {
  print("Test CallbackOutsideIsolate.");
  CallbackTest("CallbackOutsideIsolate",
          Pointer.fromFunction<ReturnVoid>(returnVoid))
      .run();
}

void isolateHelper(int callbackPointer) {
  final Pointer<Void> ptr = Pointer<Void>.fromAddress(callbackPointer);
  final NativeCallbackTestFn tester =
      testLibrary.lookupFunction<NativeCallbackTest, NativeCallbackTestFn>(
          "TestCallbackWrongIsolate");

  // [cfe] Expect a compile-time error if this fails in the frontend
  Expect.equals(0, tester(ptr)); // [cfe] Check for CFE error
}

Future<void> testCallbackWrongIsolate() async {
  final int callbackPointer =
      Pointer.fromFunction<ReturnVoid>(returnVoid).address;
  final ReceivePort exitPort = ReceivePort();

  await Isolate.spawn(
    isolateHelper,
    callbackPointer,
    errorsAreFatal: true,
    onExit: exitPort.sendPort,
  );

  await exitPort.first;
}

void main() async {
  // These tests terminate the process after successful completion,
  // so we have to run them separately.
  //
  // Since they use signal handlers, they only run on Linux.
  if (Platform.isLinux && !const bool.fromEnvironment("dart.vm.product")) {
    testCallbackWrongThread();
    testCallbackOutsideIsolate();
    await testCallbackWrongIsolate();
  }
}
