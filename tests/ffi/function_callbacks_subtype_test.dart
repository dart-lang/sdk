// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing dart:ffi callbacks that take advantage of
// subtyping rules.
//
// VMOptions=
// VMOptions=--stacktrace-every=100
// VMOptions=--use-slow-path
// VMOptions=--use-slow-path --stacktrace-every=100
// VMOptions=--dwarf_stack_traces --no-retain_function_objects --no-retain_code_objects
// VMOptions=--test_il_serialization
// VMOptions=--profiler --profile_vm=true
// VMOptions=--profiler --profile_vm=false
// SharedObjects=ffi_test_functions

import 'dart:async';
import 'dart:ffi';

import "package:expect/expect.dart";

import 'dylib_utils.dart';

final ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");

typedef TwoIntVoidFnNativeType = Void Function(Pointer, Int32, Int32);
typedef TwoIntVoidFnType = void Function(Pointer, int, int);
final callTwoIntVoidFunction = ffiTestFunctions
    .lookupFunction<TwoIntVoidFnNativeType, TwoIntVoidFnType>(
      "CallTwoIntVoidFunction",
    );

typedef TwoIntPointerFnNativeType =
    Pointer<NativeType> Function(Pointer, Int32, Int32);
typedef TwoIntPointerFnType = Pointer<NativeType> Function(Pointer, int, int);
final callTwoIntPointerFunction = ffiTestFunctions
    .lookupFunction<TwoIntPointerFnNativeType, TwoIntPointerFnType>(
      "CallTwoIntPointerFunction",
    );

typedef TwoPointerIntFnNativeType =
    Int32 Function(Pointer, Pointer<NativeType>, Pointer<NativeType>);
typedef TwoPointerIntFnType =
    int Function(Pointer, Pointer<NativeType>, Pointer<NativeType>);
final callTwoPointerIntFunction = ffiTestFunctions
    .lookupFunction<TwoPointerIntFnNativeType, TwoPointerIntFnType>(
      "CallTwoPointerIntFunction",
    );

typedef VoidReturnFunction = Void Function(Int32, Int32);
int addVoidResult = 0;
int addVoid(int x, int y) {
  print("addVoid($x, $y)");
  addVoidResult = x + y;
  return addVoidResult;
}

final addVoidAsyncResult = Completer<int>();
int addVoidAsync(int x, int y) {
  print("addVoidAsync($x, $y)");
  final result = x + y;
  addVoidAsyncResult.complete(result);
  return result;
}

typedef NaTyPtrReturnFunction = Pointer<NativeType> Function(Int32, Int32);
Pointer<Int64> addInt64PtrReturn(int x, int y) {
  print("addInt64PtrReturn($x, $y)");
  return Pointer<Int64>.fromAddress(x + y);
}

typedef Int64PtrParamFunction = Int32 Function(Pointer<Int64>, Pointer<Int64>);
int addNaTyPtrParam(Pointer<NativeType> x, Pointer<NativeType> y) {
  print("addNaTyPtrParam($x, $y)");
  return x.address + y.address;
}

Future<void> main() async {
  await testReturnVoid();
  testReturnSubtype();
  testParamSubtype();
  print("Done! :)");
}

Future<void> testReturnVoid() async {
  // If the native function type returns void, the Dart function can return
  // anything.
  final legacyCallback = Pointer.fromFunction<VoidReturnFunction>(addVoid);
  callTwoIntVoidFunction(legacyCallback, 100, 23);
  Expect.equals(123, addVoidResult);

  final isolateLocal = NativeCallable<VoidReturnFunction>.isolateLocal(addVoid)
    ..keepIsolateAlive = false;
  callTwoIntVoidFunction(isolateLocal.nativeFunction, 400, 56);
  Expect.equals(456, addVoidResult);

  final listener = NativeCallable<VoidReturnFunction>.listener(addVoidAsync)
    ..keepIsolateAlive = false;
  callTwoIntVoidFunction(listener.nativeFunction, 700, 89);
  Expect.equals(789, await addVoidAsyncResult.future);
}

void testReturnSubtype() {
  // The Dart function is allowed to return a subtype of the native return type.
  final legacyCallback = Pointer.fromFunction<NaTyPtrReturnFunction>(
    addInt64PtrReturn,
  );
  Expect.equals(
    123,
    callTwoIntPointerFunction(legacyCallback, 100, 23).address,
  );

  final isolateLocal = NativeCallable<NaTyPtrReturnFunction>.isolateLocal(
    addInt64PtrReturn,
  )..keepIsolateAlive = false;
  Expect.equals(
    456,
    callTwoIntPointerFunction(isolateLocal.nativeFunction, 400, 56).address,
  );
}

void testParamSubtype() {
  // The Dart function is allowed to accept params that are a supertype of the
  // native type's params.
  final legacyCallback = Pointer.fromFunction<Int64PtrParamFunction>(
    addNaTyPtrParam,
    0,
  );
  Expect.equals(
    123,
    callTwoPointerIntFunction(
      legacyCallback,
      Pointer<Int64>.fromAddress(100),
      Pointer<Int64>.fromAddress(23),
    ),
  );

  final isolateLocal = NativeCallable<Int64PtrParamFunction>.isolateLocal(
    addNaTyPtrParam,
    exceptionalReturn: 0,
  )..keepIsolateAlive = false;
  Expect.equals(
    456,
    callTwoPointerIntFunction(
      isolateLocal.nativeFunction,
      Pointer<Int64>.fromAddress(400),
      Pointer<Int64>.fromAddress(56),
    ),
  );
}
