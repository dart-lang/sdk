// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
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
import "package:expect/expect.dart";
import 'dylib_utils.dart';

typedef NativeCallbackTest = Int32 Function(Pointer);
typedef NativeCallbackTestFn = int Function(Pointer);
final DynamicLibrary testLibrary = dlopenPlatformSpecific("ffi_test_functions");

class Test {
  final String name;
  final Pointer callback;
  final bool skip;
  Test(this.name, this.callback, {bool skipIf: false}) : skip = skipIf {}
  void run() {
    if (skip) return;
    print("Test $name.");
    final NativeCallbackTestFn tester = testLibrary
        .lookupFunction<NativeCallbackTest, NativeCallbackTestFn>("Test$name");
    final int testCode = tester(callback);
    if (testCode != 0) {
      Expect.fail("Test $name failed.");
    }
  }
}

typedef ReturnVoid = Void Function();
void returnVoid() {}
testCallbackWrongThread() {
  print("Test CallbackWrongThread.");
  Test("CallbackWrongThread", Pointer.fromFunction<ReturnVoid>(returnVoid))
      .run();
}

testCallbackOutsideIsolate() {
  print("Test CallbackOutsideIsolate.");
  Test("CallbackOutsideIsolate", Pointer.fromFunction<ReturnVoid>(returnVoid))
      .run();
}

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

void main() async {
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
