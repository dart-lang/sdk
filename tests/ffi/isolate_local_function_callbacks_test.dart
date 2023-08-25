// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing dart:ffi async callbacks.
//
// VMOptions=--stacktrace-every=100
// VMOptions=--write-protect-code --no-dual-map-code
// VMOptions=--write-protect-code --no-dual-map-code --stacktrace-every=100
// VMOptions=--use-slow-path
// VMOptions=--use-slow-path --stacktrace-every=100
// VMOptions=--use-slow-path --write-protect-code --no-dual-map-code
// VMOptions=--use-slow-path --write-protect-code --no-dual-map-code --stacktrace-every=100
// VMOptions=--dwarf_stack_traces --no-retain_function_objects --no-retain_code_objects
// VMOptions=--test_il_serialization
// VMOptions=--profiler
// SharedObjects=ffi_test_functions

import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:math';

import 'dart:io';

import "package:expect/expect.dart";

import 'dylib_utils.dart';

main(args, message) async {
  testNativeCallableStatic();
  testNativeCallableClosure();
  testNativeCallableDoubleCloseError();
  testNativeCallableNestedCloseCallStatic();
  testNativeCallableNestedCloseCallClosure();
  testNativeCallableExceptionalReturnStatic();
  testNativeCallableExceptionalReturnClosure();
  await testNativeCallableDontKeepAliveStatic();
  await testNativeCallableDontKeepAliveClosure();
  testNativeCallableKeepAliveGetter();
  print("All tests completed :)");
}

final ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");

typedef TwoIntFnNativeType = Int32 Function(Pointer, Int32, Int32);
typedef TwoIntFnType = int Function(Pointer, int, int);
final callTwoIntFunction = ffiTestFunctions
    .lookupFunction<TwoIntFnNativeType, TwoIntFnType>("CallTwoIntFunction");

typedef CallbackNativeType = Int32 Function(Int32, Int32);
int add(int a, int b) {
  return a + b;
}

testNativeCallableStatic() {
  final callback = NativeCallable<CallbackNativeType>.isolateLocal(add,
      exceptionalReturn: 0);

  Expect.equals(1234, callTwoIntFunction(callback.nativeFunction, 1000, 234));

  callback.close();
}

testNativeCallableClosure() {
  int c = 70000;
  int closure(int a, int b) {
    return a + b + c;
  }

  final callback = NativeCallable<CallbackNativeType>.isolateLocal(closure,
      exceptionalReturn: 0);

  Expect.equals(71234, callTwoIntFunction(callback.nativeFunction, 1000, 234));

  c = 80000;
  Expect.equals(81234, callTwoIntFunction(callback.nativeFunction, 1000, 234));

  callback.close();
}

testNativeCallableDoubleCloseError() {
  final callback = NativeCallable<CallbackNativeType>.isolateLocal(add,
      exceptionalReturn: 0);
  Expect.notEquals(nullptr, callback.nativeFunction);
  callback.close();
  Expect.equals(nullptr, callback.nativeFunction);
  Expect.throwsStateError(() {
    callback.close();
  });
}

late NativeCallable selfClosingStaticCallback;
int selfClosingStatic(int a, int b) {
  selfClosingStaticCallback.close();
  return a + b;
}

testNativeCallableNestedCloseCallStatic() {
  selfClosingStaticCallback = NativeCallable<CallbackNativeType>.isolateLocal(
      selfClosingStatic,
      exceptionalReturn: 0);

  Expect.equals(1234,
      callTwoIntFunction(selfClosingStaticCallback.nativeFunction, 1000, 234));

  // The callback is already closed.
  Expect.equals(nullptr, selfClosingStaticCallback.nativeFunction);
}

testNativeCallableNestedCloseCallClosure() {
  late NativeCallable callback;

  int selfClosing(int a, int b) {
    callback.close();
    return a + b;
  }

  callback = NativeCallable<CallbackNativeType>.isolateLocal(selfClosing,
      exceptionalReturn: 0);

  Expect.equals(1234, callTwoIntFunction(callback.nativeFunction, 1000, 234));

  // The callback is already closed.
  Expect.equals(nullptr, callback.nativeFunction);
}

int throwerCallback(int a, int b) {
  if (a != 1000) {
    throw "Oh no!";
  }
  return a + b;
}

testNativeCallableExceptionalReturnStatic() {
  final callback = NativeCallable<CallbackNativeType>.isolateLocal(
      throwerCallback,
      exceptionalReturn: 5678);

  Expect.equals(1234, callTwoIntFunction(callback.nativeFunction, 1000, 234));
  Expect.equals(5678, callTwoIntFunction(callback.nativeFunction, 0, 0));

  callback.close();
}

testNativeCallableExceptionalReturnClosure() {
  int thrower(int a, int b) {
    if (a != 1000) {
      throw "Oh no!";
    }
    return a + b;
  }

  final callback = NativeCallable<CallbackNativeType>.isolateLocal(thrower,
      exceptionalReturn: 5678);

  Expect.equals(1234, callTwoIntFunction(callback.nativeFunction, 1000, 234));
  Expect.equals(5678, callTwoIntFunction(callback.nativeFunction, 0, 0));

  callback.close();
}

Future<void> testNativeCallableDontKeepAliveStatic() async {
  final exitPort = ReceivePort();
  await Isolate.spawn((_) async {
    final callback = NativeCallable<CallbackNativeType>.isolateLocal(add,
        exceptionalReturn: 0);

    Expect.equals(1234, callTwoIntFunction(callback.nativeFunction, 1000, 234));

    callback.keepIsolateAlive = false;
  }, null, onExit: exitPort.sendPort);
  await exitPort.first;
  exitPort.close();
}

Future<void> testNativeCallableDontKeepAliveClosure() async {
  int c = 70000;
  int closure(int a, int b) {
    return a + b + c;
  }

  final exitPort = ReceivePort();
  await Isolate.spawn((_) async {
    final callback = NativeCallable<CallbackNativeType>.isolateLocal(closure,
        exceptionalReturn: 0);

    Expect.equals(
        71234, callTwoIntFunction(callback.nativeFunction, 1000, 234));

    callback.keepIsolateAlive = false;
  }, null, onExit: exitPort.sendPort);
  await exitPort.first;
  exitPort.close();
}

testNativeCallableKeepAliveGetter() {
  final callback = NativeCallable<CallbackNativeType>.isolateLocal(add,
      exceptionalReturn: 0);
  // Check that only the flag changes are counted by decrementing and
  // incrementing a lot, and by different amounts.
  for (int i = 0; i < 100; ++i) {
    callback.keepIsolateAlive = false;
    Expect.isFalse(callback.keepIsolateAlive);
  }
  for (int i = 0; i < 200; ++i) {
    callback.keepIsolateAlive = true;
    Expect.isTrue(callback.keepIsolateAlive);
  }
  callback.close();
}
