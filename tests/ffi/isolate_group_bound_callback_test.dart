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

class NativeLibrary {
  late final FnRunnerType callFunctionOnSameThread;
  late final FnRunnerType callFunctionOnNewThreadBlocking;
  late final FnRunnerType callFunctionOnNewThreadNonBlocking;
  late final TwoIntFnType callTwoIntFunction;
  late final FnSleepType sleep;

  NativeLibrary(DynamicLibrary ffiTestFunctions) {
    callFunctionOnNewThreadNonBlocking = ffiTestFunctions
        .lookupFunction<FnRunnerNativeType, FnRunnerType>(
          "CallFunctionOnNewThreadNonBlocking",
        );
    callFunctionOnNewThreadBlocking = ffiTestFunctions
        .lookupFunction<FnRunnerNativeType, FnRunnerType>(
          "CallFunctionOnNewThreadBlocking",
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

const int sleepForMs = 1000;

void simpleFunction(int a, int b) {
  result += (a * b);
  final ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");
  final lib = NativeLibrary(ffiTestFunctions);
  lib.sleep(sleepForMs);
  mutexCondvar.runLocked(() {
    resultIsReady = true;
    conditionVariable.notify();
  });
}

Future<void> testNativeCallableHelloWorld(NativeLibrary lib) async {
  mutexCondvar = Mutex();
  conditionVariable = ConditionVariable();
  final callback = NativeCallable<CallbackNativeType>.isolateGroupBound(
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
  callback.close();
}

void simpleFunctionThatThrows(int a, int b) {
  // Complete without notifying mutexCondvar
  throw 'hello, world';
}

Future<void> testNativeCallableThrows(NativeLibrary lib) async {
  mutexCondvar = Mutex();
  conditionVariable = ConditionVariable();
  final callback = NativeCallable<CallbackNativeType>.isolateGroupBound(
    simpleFunctionThatThrows,
  );

  result = 42;
  resultIsReady = false;
  // The call is blocking so that tsan does not complain about read/write
  // race between invoking the callback and closing it few lines down below.
  // So the main thing this test checks is condition variable timeout,
  // which is still valuable.
  lib.callFunctionOnNewThreadBlocking(1001, callback.nativeFunction);

  mutexCondvar.runLocked(() {
    // Just have short one second sleep - the condition variable is not
    // going to be triggered.
    conditionVariable.wait(mutexCondvar, 1 * sleepForMs);
    Expect.isFalse(resultIsReady);
  });
  callback.close();
}

Future<void> testNativeCallableHelloWorldClosure(NativeLibrary lib) async {
  mutexCondvar = Mutex();
  conditionVariable = ConditionVariable();
  final callback = NativeCallable<CallbackNativeType>.isolateGroupBound((
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
  callback.close();
}

void testNativeCallableSync(NativeLibrary lib) {
  final callback =
      NativeCallable<CallbackReturningIntNativeType>.isolateGroupBound((
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

void testNativeCallableSyncThrows(NativeLibrary lib) {
  final callback =
      NativeCallable<CallbackReturningIntNativeType>.isolateGroupBound(
        (int a, int b) {
              throw "foo";
            }
            as int Function(int, int),
        exceptionalReturn: 1111,
      );

  Expect.equals(
    1111,
    lib.callTwoIntFunction(callback.nativeFunction, 1000, 234),
  );
  callback.close();
}

int isolateVar = 10;

void testNativeCallableAccessNonSharedVar(NativeLibrary lib) {
  final callback =
      NativeCallable<CallbackReturningIntNativeType>.isolateGroupBound((
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

Future<void> testKeepIsolateAliveTrue() async {
  mutexCondvar = Mutex();
  conditionVariable = ConditionVariable();
  ReceivePort rpOnExit = ReceivePort("onExit");
  unawaited(
    Isolate.spawn(
      (_) async {
        final callback = NativeCallable<CallbackNativeType>.isolateGroupBound(
          simpleFunction,
        );
        callback.keepIsolateAlive = true;
      },
      /*message=*/ null,
      onExit: rpOnExit.sendPort,
    ),
  );
  try {
    await rpOnExit.first.timeout(Duration(seconds: 5));
    // should not fall through, should throw TimeoutException
    Expect.isTrue(false);
  } catch (e) {
    print('testKeepIsolateAliveTrue caught $e');
    Expect.isTrue(e is TimeoutException);
  }
  rpOnExit.close();
}

Future<void> testKeepIsolateAliveFalse() async {
  mutexCondvar = Mutex();
  conditionVariable = ConditionVariable();
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
  final ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");
  final lib = NativeLibrary(ffiTestFunctions);
  await testNativeCallableHelloWorld(lib);
  await testNativeCallableThrows(lib);
  await testNativeCallableHelloWorldClosure(lib);
  testNativeCallableSync(lib);
  testNativeCallableSyncThrows(lib);
  testNativeCallableAccessNonSharedVar(lib);
  await testKeepIsolateAliveTrue();
  await testKeepIsolateAliveFalse();
  asyncEnd();
  print("All tests completed :)");
}
