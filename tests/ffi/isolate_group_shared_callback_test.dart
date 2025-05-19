// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing dart:ffi async callbacks.
//
// VMOptions=--experimental-shared-data --print-stacktrace-at-throw
// VMOptions=--experimental-shared-data --print-stacktrace-at-throw --use-slow-path
// VMOptions=--experimental-shared-data --print-stacktrace-at-throw --use-slow-path --stacktrace-every=100
// VMOptions=--experimental-shared-data --print-stacktrace-at-throw --use-slow-path --shared_slow_path_triggers_gc
// VMOptions=--experimental-shared-data --print-stacktrace-at-throw --dwarf_stack_traces --no-retain_function_objects --no-retain_code_objects
// VMOptions=--experimental-shared-data --print-stacktrace-at-throw --test_il_serialization
// VMOptions=--experimental-shared-data --print-stacktrace-at-throw --profiler --profile_vm=true
// VMOptions=--experimental-shared-data --print-stacktrace-at-throw --profiler --profile_vm=false
// SharedObjects=ffi_test_functions

import 'dart:async';
import 'dart:concurrent';
import 'dart:ffi';
import 'dart:isolate';
import 'package:dart_internal/isolate_group.dart' show IsolateGroup;

import 'dart:io';

import "package:expect/expect.dart";

import 'dylib_utils.dart';

typedef CallbackNativeType = Void Function(Int64, Int32);
typedef CallbackReturningIntNativeType = Int32 Function(Int32, Int32);

final ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");

typedef FnRunnerNativeType = Void Function(Int64, Pointer);
typedef FnRunnerType = void Function(int, Pointer);
typedef FnSleepNativeType = Void Function(Int32);
typedef FnSleepType = void Function(int);

typedef TwoIntFnNativeType = Int32 Function(Pointer, Int32, Int32);
typedef TwoIntFnType = int Function(Pointer, int, int);

class NativeLibrary {
  late final FnRunnerType callFunctionOnSameThread;
  late final FnRunnerType callFunctionOnNewThreadBlocking;
  late final FnRunnerType callFunctionOnNewThreadNonBlocking;
  late final TwoIntFnType callTwoIntFunction;
  late final FnSleepType sleep;

  NativeLibrary() {
    callFunctionOnNewThreadNonBlocking = ffiTestFunctions
        .lookupFunction<FnRunnerNativeType, FnRunnerType>(
          "CallFunctionOnNewThreadNonBlocking",
        );
    callTwoIntFunction = ffiTestFunctions
        .lookupFunction<TwoIntFnNativeType, TwoIntFnType>("CallTwoIntFunction");
    sleep = ffiTestFunctions.lookupFunction<FnSleepNativeType, FnSleepType>(
      "SleepFor",
    );
  }
}

@pragma('vm:shared')
late Mutex mutexCondvar;
@pragma('vm:shared')
late ConditionVariable conditionVariable;

@pragma('vm:shared')
int result = 0;
@pragma('vm:shared')
bool resultIsReady = false;

@pragma('vm:shared')
late NativeLibrary lib;

const int sleepForMs = 1000;

void simpleFunction(int a, int b) {
  result += (a * b);
  lib.sleep(sleepForMs);
  mutexCondvar.runLocked(() {
    resultIsReady = true;
    conditionVariable.notify();
  });
}

Future<void> testNativeCallableHelloWorld() async {
  mutexCondvar = Mutex();
  conditionVariable = ConditionVariable();
  final callback = NativeCallable<CallbackNativeType>.isolateGroupShared(
    simpleFunction,
  );

  result = 42;
  resultIsReady = false;
  lib.callFunctionOnNewThreadNonBlocking(1001, callback.nativeFunction);

  mutexCondvar.runLocked(() {
    while (!resultIsReady) {
      conditionVariable.wait(mutexCondvar, 10 * sleepForMs);
      print('.');
    }
  });

  Expect.equals(42 + (1001 * 123), result);

  resultIsReady = false;
  lib.callFunctionOnNewThreadNonBlocking(1001, callback.nativeFunction);
  mutexCondvar.runLocked(() {
    while (!resultIsReady) {
      conditionVariable.wait(mutexCondvar, 10 * sleepForMs);
      print('.');
    }
  });
  Expect.equals(42 + (1001 * 123) * 2, result);
}

void simpleFunctionThatThrows(int a, int b) {
  // Complete without notifying mutexCondvar
  throw 'hello, world';
}

Future<void> testNativeCallableThrows() async {
  mutexCondvar = Mutex();
  conditionVariable = ConditionVariable();
  final callback = NativeCallable<CallbackNativeType>.isolateGroupShared(
    simpleFunctionThatThrows,
  );

  result = 42;
  resultIsReady = false;
  lib.callFunctionOnNewThreadNonBlocking(1001, callback.nativeFunction);

  mutexCondvar.runLocked(() {
    conditionVariable.wait(mutexCondvar, 10 * sleepForMs);
    Expect.isFalse(resultIsReady);
  });
}

Future<void> testNativeCallableHelloWorldClosure() async {
  mutexCondvar = Mutex();
  conditionVariable = ConditionVariable();
  final callback = NativeCallable<CallbackNativeType>.isolateGroupShared((
    int a,
    int b,
  ) {
    result += (a * b);
    lib.sleep(sleepForMs);
    mutexCondvar.runLocked(() {
      resultIsReady = true;
      conditionVariable.notify();
    });
  });

  result = 42;
  resultIsReady = false;
  lib.callFunctionOnNewThreadNonBlocking(1001, callback.nativeFunction);

  mutexCondvar.runLocked(() {
    while (!resultIsReady) {
      conditionVariable.wait(mutexCondvar);
    }
  });

  Expect.equals(42 + (1001 * 123), result);

  resultIsReady = false;
  lib.callFunctionOnNewThreadNonBlocking(1001, callback.nativeFunction);
  mutexCondvar.runLocked(() {
    while (!resultIsReady) {
      conditionVariable.wait(mutexCondvar);
    }
  });
  Expect.equals(42 + (1001 * 123) * 2, result);
}

void testNativeCallableSync() {
  final callback =
      NativeCallable<CallbackReturningIntNativeType>.isolateGroupShared((
        int a,
        int b,
      ) {
        return a + b;
      }, exceptionalReturn: 1111);

  Expect.equals(
    1234,
    lib.callTwoIntFunction(callback.nativeFunction, 1000, 234),
  );
  callback.close();
}

void testNativeCallableSyncThrows() {
  final callback =
      NativeCallable<CallbackReturningIntNativeType>.isolateGroupShared((
        int a,
        int b,
      ) {
        throw "foo";
        return a + b;
      }, exceptionalReturn: 1111);

  Expect.equals(
    1111,
    lib.callTwoIntFunction(callback.nativeFunction, 1000, 234),
  );
  callback.close();
}

int isolateVar = 10;

void testNativeCallableAccessNonSharedVar() {
  final callback =
      NativeCallable<CallbackReturningIntNativeType>.isolateGroupShared((
        int a,
        int b,
      ) {
        return isolateVar - a + b;
      }, exceptionalReturn: 1111);

  isolateVar = 42;
  Expect.equals(
    1111,
    lib.callTwoIntFunction(callback.nativeFunction, 1000, 234),
  );
  callback.close();
}

main(args, message) async {
  lib = NativeLibrary();
  // Simple tests.
  await testNativeCallableHelloWorld();
  await testNativeCallableThrows();
  await testNativeCallableHelloWorldClosure();
  testNativeCallableSync();
  testNativeCallableSyncThrows();
  testNativeCallableAccessNonSharedVar();
  print("All tests completed :)");
}
