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

import 'dart:io';
import 'dart:ffi';
import 'dart:isolate';
import 'dylib_utils.dart';

import "package:expect/expect.dart";

import 'ffi_test_helpers.dart';
import 'function_callbacks_test.dart' show Test, testLibrary,
       NativeCallbackTest, NativeCallbackTestFn, ReturnVoid, returnVoid;

void testGC() {
  triggerGc();
}

typedef WaitForHelperNative = Void Function(Pointer<Void>);
typedef WaitForHelper = void Function(Pointer<Void>);

void waitForHelper(Pointer<Void> helper) {
  print("helper: $helper");
  testLibrary
      .lookupFunction<WaitForHelperNative, WaitForHelper>("WaitForHelper")(helper);
}

final List<Test> testcases = [
  Test("GC", Pointer.fromFunction<ReturnVoid>(testGC)),
  Test("UnprotectCode", Pointer.fromFunction<WaitForHelperNative>(waitForHelper)),
];

testCallbackWrongThread() =>
    Test("CallbackWrongThread", Pointer.fromFunction<ReturnVoid>(returnVoid))
        .run();

testCallbackOutsideIsolate() =>
    Test("CallbackOutsideIsolate", Pointer.fromFunction<ReturnVoid>(returnVoid))
        .run();

isolateHelper(int callbackPointer) {
  final Pointer<Void> ptr = Pointer.fromAddress(callbackPointer);
  final NativeCallbackTestFn tester =
      testLibrary.lookupFunction<NativeCallbackTest, NativeCallbackTestFn>(
          "TestCallbackWrongIsolate");
  Expect.equals(0, tester(ptr));
}

testCallbackWrongIsolate() async {
  final int callbackPointer =
      Pointer.fromFunction<ReturnVoid>(returnVoid).address;
  final ReceivePort exitPort = ReceivePort();
  await Isolate.spawn(isolateHelper, callbackPointer,
      errorsAreFatal: true, onExit: exitPort.sendPort);
  await exitPort.first;
}

const double zeroPointZero = 0.0;

// Correct type of exceptionalReturn argument to Pointer.fromFunction.
double testExceptionalReturn() {
  Pointer.fromFunction<Double Function()>(testExceptionalReturn, 0.0);
  Pointer.fromFunction<Double Function()>(testExceptionalReturn, zeroPointZero);

  Pointer.fromFunction<Double Function()>(returnVoid, null);  //# 59: compile-time error
  Pointer.fromFunction<Void Function()>(returnVoid, 0);  //# 60: compile-time error
  Pointer.fromFunction<Double Function()>(testExceptionalReturn, "abc");  //# 61: compile-time error
  Pointer.fromFunction<Double Function()>(testExceptionalReturn, 0);  //# 62: compile-time error
  Pointer.fromFunction<Double Function()>(testExceptionalReturn);  //# 63: compile-time error

  return 0.0;  // not used
}

void main() async {
  testcases.forEach((t) => t.run()); //# 00: ok
  testExceptionalReturn(); //# 00: ok

  // These tests terminate the process after successful completion, so we have
  // to run them separately.
  //
  // Since they use signal handlers they only run on Linux.
  if (Platform.isLinux && !const bool.fromEnvironment("dart.vm.product")) {
    testCallbackWrongThread(); //# 01: ok
    testCallbackOutsideIsolate(); //# 02: ok
    await testCallbackWrongIsolate(); //# 03: ok
  }
}
