// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing dart:ffi async callbacks.
//
// VMOptions=
// VMOptions=--use-slow-path
// VMOptions=--use-slow-path --stacktrace-every=100
// VMOptions=--dwarf_stack_traces --no-retain_function_objects --no-retain_code_objects
// VMOptions=--test_il_serialization
// VMOptions=--profiler --profile_vm=true
// VMOptions=--profiler --profile_vm=false
// SharedObjects=ffi_test_functions

import 'dart:ffi';

import 'dart:io';

import 'package:expect/expect.dart';

import 'dylib_utils.dart';

main() {
  testNativeCallableHelloWorld();

  print('All tests completed :)');
}

int simpleFunction(int a, int b) {
  return a + b;
}

Future<void> testNativeCallableHelloWorld() async {
  final callback = NativeCallable<Int32 Function(Int32, Int32)>.isolateLocal(
    simpleFunction,
    exceptionalReturn: 0,
  );

  final result = callTwoIntFunctionIsolateOwnership(
    clearCurrentThreadOwnsIsolatePointer,
    callback.nativeFunction,
    123,
    1000,
  );

  Expect.equals(1123, result);
  callback.close();
}

final ffiTestFunctions = dlopenPlatformSpecific('ffi_test_functions');

typedef FnRunnerNativeType = Int32 Function(Pointer, Pointer, Int32, Int32);
typedef FnRunnerType = int Function(Pointer, Pointer, int, int);
final FnRunnerType callTwoIntFunctionIsolateOwnership = ffiTestFunctions
    .lookupFunction<FnRunnerNativeType, FnRunnerType>(
      'CallTwoIntFunctionIsolateOwnership',
    );

final Pointer clearCurrentThreadOwnsIsolatePointer = DynamicLibrary.process()
    .lookup<NativeFunction<Void Function()>>(
      'Dart_ClearCurrentThreadOwnsIsolate_ForTesting',
    );
