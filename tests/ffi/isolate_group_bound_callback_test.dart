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
import 'dart:io' show Platform;
import 'dart:isolate';
import 'dart:typed_data';

import "package:expect/async_helper.dart";
import "package:expect/expect.dart";

typedef CallbackNativeType = Void Function(Int64, Int32);
typedef CallbackReturningIntNativeType = Int32 Function(Int32, Int32);

typedef FnRunnerNativeType = Void Function(Int64, Pointer);
typedef FnRunnerType = void Function(int, Pointer);
typedef FnSleepNativeType = Void Function(Int32);
typedef FnSleepType = void Function(int);

typedef TwoIntFnNativeType = Int32 Function(Pointer, Int32, Int32);
typedef TwoIntFnType = int Function(Pointer, int, int);

@pragma('vm:shared')
final _dylibExtension = () {
  if (Platform.isLinux || Platform.isAndroid || Platform.isFuchsia)
    return '.so';
  if (Platform.isMacOS) return '.dylib';
  if (Platform.isWindows) return '.dll';
  throw Exception('Platform not implemented.');
}();

@pragma('vm:shared')
final _dylibPrefix = Platform.isWindows ? '' : 'lib';

DynamicLibrary dlopenPlatformSpecific(String name) {
  return DynamicLibrary.open('$_dylibPrefix$name$_dylibExtension');
}

DynamicLibrary get ffiTestFunctions =>
    dlopenPlatformSpecific("ffi_test_functions");

FnRunnerType get callFunctionOnNewThreadNonBlocking =>
    ffiTestFunctions.lookupFunction<FnRunnerNativeType, FnRunnerType>(
      "CallFunctionOnNewThreadNonBlocking",
    );

FnRunnerType get callFunctionOnNewThreadBlocking =>
    ffiTestFunctions.lookupFunction<FnRunnerNativeType, FnRunnerType>(
      "CallFunctionOnNewThreadBlocking",
    );

TwoIntFnType get callTwoIntFunction => ffiTestFunctions
    .lookupFunction<TwoIntFnNativeType, TwoIntFnType>("CallTwoIntFunction");

FnSleepType get sleep =>
    ffiTestFunctions.lookupFunction<FnSleepNativeType, FnSleepType>("SleepFor");

@pragma('vm:shared')
final mutexCondvar = Mutex();
@pragma('vm:shared')
final conditionVariable = ConditionVariable();

@pragma('vm:shared')
final result = Uint32List(1);
@pragma('vm:shared')
final resultIsReady = Uint8List(1);

const int sleepForMs = 1000;

void simpleFunction(int a, int b) {
  result[0] += (a * b);
  sleep(sleepForMs);
  mutexCondvar.runLocked(() {
    resultIsReady[0] = 1;
    conditionVariable.notify();
  });
}

Future<void> testNativeCallableHelloWorld() async {
  final callback = NativeCallable<CallbackNativeType>.isolateGroupBound(
    simpleFunction,
  );

  result[0] = 42;
  resultIsReady[0] = 0;
  callFunctionOnNewThreadNonBlocking(1001, callback.nativeFunction);

  mutexCondvar.runLocked(() {
    while (resultIsReady[0] == 0) {
      conditionVariable.wait(mutexCondvar, 10 * sleepForMs);
      print('.');
    }
  });

  Expect.equals(42 + (1001 * 123), result[0]);

  resultIsReady[0] = 0;
  callFunctionOnNewThreadNonBlocking(1001, callback.nativeFunction);
  mutexCondvar.runLocked(() {
    while (resultIsReady[0] == 0) {
      conditionVariable.wait(mutexCondvar, 10 * sleepForMs);
      print('.');
    }
  });
  Expect.equals(42 + (1001 * 123) * 2, result[0]);
  callback.close();
}

void simpleFunctionThatThrows(int a, int b) {
  // Complete without notifying mutexCondvar
  throw 'hello, world';
}

Future<void> testNativeCallableThrows() async {
  final callback = NativeCallable<CallbackNativeType>.isolateGroupBound(
    simpleFunctionThatThrows,
  );

  result[0] = 42;
  resultIsReady[0] = 0;
  // The call is blocking so that tsan does not complain about read/write
  // race between invoking the callback and closing it few lines down below.
  // So the main thing this test checks is condition variable timeout,
  // which is still valuable.
  callFunctionOnNewThreadBlocking(1001, callback.nativeFunction);

  mutexCondvar.runLocked(() {
    // Just have short one second sleep - the condition variable is not
    // going to be triggered.
    conditionVariable.wait(mutexCondvar, 1 * sleepForMs);
    Expect.equals(0, resultIsReady[0]);
  });
  callback.close();
}

Future<void> testFailToCaptureReceivePort() async {
  final rp = ReceivePort();
  Expect.throws(
    () {
      NativeCallable<CallbackNativeType>.isolateGroupBound((int a, int b) {
        print(rp.sendPort);
      });
    },
    (e) =>
        e is ArgumentError && e.toString().contains('Only trivially-immutable'),
  );
  rp.close();
}

Future<void> testNativeCallableHelloWorldClosure() async {
  final callback = NativeCallable<CallbackNativeType>.isolateGroupBound((
    int a,
    int b,
  ) {
    result[0] += (a * b);
    sleep(sleepForMs);
    mutexCondvar.runLocked(() {
      resultIsReady[0] = 1;
      conditionVariable.notify();
    });
  });

  result[0] = 42;
  resultIsReady[0] = 0;
  callFunctionOnNewThreadNonBlocking(1001, callback.nativeFunction);

  mutexCondvar.runLocked(() {
    while (resultIsReady[0] == 0) {
      conditionVariable.wait(mutexCondvar);
    }
  });

  Expect.equals(42 + (1001 * 123), result[0]);

  resultIsReady[0] = 0;
  callFunctionOnNewThreadNonBlocking(1001, callback.nativeFunction);
  mutexCondvar.runLocked(() {
    while (resultIsReady[0] == 0) {
      conditionVariable.wait(mutexCondvar);
    }
  });
  Expect.equals(42 + (1001 * 123) * 2, result[0]);
  callback.close();
}

void testNativeCallableSync() {
  final callback =
      NativeCallable<CallbackReturningIntNativeType>.isolateGroupBound((
        int a,
        int b,
      ) {
        return a + b;
      }, exceptionalReturn: 1111);

  Expect.equals(1234, callTwoIntFunction(callback.nativeFunction, 1000, 234));
  callback.close();
}

void testNativeCallableSyncThrows() {
  final callback =
      NativeCallable<CallbackReturningIntNativeType>.isolateGroupBound(
        (int a, int b) {
              throw "foo";
            }
            as int Function(int, int),
        exceptionalReturn: 1111,
      );

  Expect.equals(1111, callTwoIntFunction(callback.nativeFunction, 1000, 234));
  callback.close();
}

int isolateVar = 10;

void testNativeCallableAccessNonSharedVar() {
  final callback =
      NativeCallable<CallbackReturningIntNativeType>.isolateGroupBound((
        int a,
        int b,
      ) {
        return isolateVar - a + b;
      }, exceptionalReturn: 1111);

  isolateVar = 42;
  Expect.equals(1111, callTwoIntFunction(callback.nativeFunction, 1000, 234));
  callback.close();
}

Future<void> testKeepIsolateAliveTrueThrows() async {
  final callback = NativeCallable<CallbackNativeType>.isolateGroupBound(
    simpleFunction,
  );
  Expect.throwsArgumentError(() {
    callback.keepIsolateAlive = true;
  });
  print(callback.nativeFunction);
  callback.close();
  Expect.throwsStateError(() {
    print(callback.nativeFunction);
  });
}

Future<void> testKeepIsolateAliveFalse() async {
  ReceivePort rpOnExit = ReceivePort("onExit");
  unawaited(
    Isolate.spawn(
      (_) async {
        final callback = NativeCallable<CallbackNativeType>.isolateGroupBound(
          simpleFunction,
        );
        callback.keepIsolateAlive = false;
      },
      /*message=*/ null,
      onExit: rpOnExit.sendPort,
    ),
  );
  try {
    await rpOnExit.first.timeout(Duration(seconds: 30));
  } catch (e) {
    // should not throw timeout exception
    print('testKeepIsolateAliveFalse caught $e');
    throw e;
  }
  rpOnExit.close();
}

main(args, message) async {
  asyncStart();
  // Simple tests.
  await testNativeCallableHelloWorld();
  await testNativeCallableThrows();
  await testFailToCaptureReceivePort();
  await testNativeCallableHelloWorldClosure();
  testNativeCallableSync();
  testNativeCallableSyncThrows();
  testNativeCallableAccessNonSharedVar();
  await testKeepIsolateAliveTrueThrows();
  await testKeepIsolateAliveFalse();
  asyncEnd();
  print("All tests completed :)");
}
