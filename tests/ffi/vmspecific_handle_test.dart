// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedObjects=ffi_test_functions
// VMOptions=--enable-testing-pragmas

import 'dart:ffi';

import 'package:expect/expect.dart';

import 'dylib_utils.dart';

void main() {
  testHandle();
  testReadField();
  testTrueHandle();
  testClosureCallback();
  testReturnHandleInCallback();
  testPropagateError();
  testCallbackReturnException();
  testDeepException();
  testDeepException2();
  testNull();
  testDeepRecursive();
  testNoHandlePropagateError();
}

void testHandle() {
  print("testHandle");
  final s = SomeClass(123);
  print("passObjectToC($s)");
  final result = passObjectToC(s);
  print("result = $result");
  Expect.isTrue(identical(s, result));
}

void testReadField() {
  final s = SomeClass(123);
  final result = handleReadFieldValue(s);
  Expect.equals(s.a, result);
}

void testTrueHandle() {
  final result = trueHandle();
  Expect.isTrue(result);
}

int globalCounter = 0;

void increaseCounter() {
  print("increaseCounter");
  globalCounter++;
}

void doClosureCallback(Object callback) {
  print("doClosureCallback");
  print(callback.runtimeType);
  print(callback);
  final callback_as_function = callback as void Function();
  callback_as_function();
}

final closureCallbackPointer =
    Pointer.fromFunction<Void Function(Handle)>(doClosureCallback);

void testClosureCallback() {
  print("testClosureCallback $closureCallbackPointer");
  Expect.equals(0, globalCounter);
  closureCallbackThroughHandle(closureCallbackPointer, increaseCounter);
  Expect.equals(1, globalCounter);
  closureCallbackThroughHandle(closureCallbackPointer, increaseCounter);
  Expect.equals(2, globalCounter);
}

final someObject = SomeClass(12356789);

Object returnHandleCallback() {
  print("returnHandleCallback returning $someObject");
  return someObject;
}

final returnHandleCallbackPointer =
    Pointer.fromFunction<Handle Function()>(returnHandleCallback);

void testReturnHandleInCallback() {
  print("testReturnHandleInCallback");
  final result = returnHandleInCallback(returnHandleCallbackPointer);
  Expect.isTrue(identical(someObject, result));
}

class SomeClass {
  // We use this getter in the native api, don't tree shake it.
  @pragma("vm:entry-point")
  final int a;
  SomeClass(this.a);
}

void testPropagateError() {
  final s = SomeOtherClass(123);
  Expect.throws(() => handleReadFieldValue(s));
}

class SomeOtherClass {
  final int notA;
  SomeOtherClass(this.notA);
}

final someException = Exception("exceptionHandleCallback exception");

Object exceptionHandleCallback() {
  print("exceptionHandleCallback throwing ($someException)");
  throw someException;
}

final exceptionHandleCallbackPointer =
    Pointer.fromFunction<Handle Function()>(exceptionHandleCallback);

void testCallbackReturnException() {
  print("testCallbackReturnException");
  bool throws = false;
  try {
    final result = returnHandleInCallback(exceptionHandleCallbackPointer);
    print(result);
  } catch (e) {
    throws = true;
    print("caught ($e)");
    Expect.isTrue(identical(someException, e));
  }
  Expect.isTrue(throws);
}

Object callCAgainFromCallback() {
  print("callCAgainFromCallback");
  final s = SomeOtherClass(123);
  Expect.throws(() => handleReadFieldValue(s));
  return someObject;
}

final callCAgainFromCallbackPointer =
    Pointer.fromFunction<Handle Function()>(callCAgainFromCallback);

void testDeepException() {
  print("testDeepException");
  final result = returnHandleInCallback(callCAgainFromCallbackPointer);
  Expect.isTrue(identical(someObject, result));
}

Object callCAgainFromCallback2() {
  print("callCAgainFromCallback2");
  final s = SomeOtherClass(123);
  handleReadFieldValue(s); // throws.
  return someObject;
}

final callCAgainFromCallbackPointer2 =
    Pointer.fromFunction<Handle Function()>(callCAgainFromCallback2);

void testDeepException2() {
  print("testDeepException2");
  Expect.throws(() => returnHandleInCallback(callCAgainFromCallbackPointer2));
}

Object? returnNullHandleCallback() {
  print("returnHandleCallback returning null");
  return null;
}

final returnNullHandleCallbackPointer =
    Pointer.fromFunction<Handle Function()>(returnNullHandleCallback);

void testNull() {
  print("testNull");
  final result = passObjectToC(null);
  Expect.isNull(result);

  final result2 = returnHandleInCallback(returnNullHandleCallbackPointer);
  Expect.isNull(result2);
}

Object recurseAbove0(int i) {
  print("recurseAbove0($i)");
  if (i == 0) {
    print("throwing");
    throw someException;
  }
  if (i < 0) {
    print("returning");
    return someObject;
  }
  final result =
      handleRecursion(SomeClassWithMethod(), recurseAbove0Pointer, i - 1);
  print("return $i");
  return result;
}

final recurseAbove0Pointer =
    Pointer.fromFunction<Handle Function(Int64)>(recurseAbove0);

class SomeClassWithMethod {
  // We use this method in the native api, don't tree shake it.
  @pragma("vm:entry-point")
  Object a(int i) => recurseAbove0(i);
}

void testDeepRecursive() {
  // works on arm.
  Expect.throws(() {
    handleRecursion(123, recurseAbove0Pointer, 1);
  });

  Expect.throws(() {
    handleRecursion(SomeClassWithMethod(), recurseAbove0Pointer, 1);
  });

  Expect.throws(() {
    recurseAbove0(100);
  });

  final result = recurseAbove0(101);
  Expect.isTrue(identical(someObject, result));
}

void testNoHandlePropagateError() {
  bool throws = false;
  try {
    final result = propagateErrorWithoutHandle(exceptionHandleCallbackPointer);
    print(result);
  } catch (e) {
    throws = true;
    print("caught ($e)");
    Expect.isTrue(identical(someException, e));
  }
  Expect.isTrue(throws);
}

final testLibrary = dlopenPlatformSpecific("ffi_test_functions");

final passObjectToC = testLibrary.lookupFunction<Handle Function(Handle),
    Object? Function(Object?)>("PassObjectToC");

final handleReadFieldValue =
    testLibrary.lookupFunction<Int64 Function(Handle), int Function(Object)>(
        "HandleReadFieldValue");

final trueHandle = testLibrary
    .lookupFunction<Handle Function(), Object Function()>("TrueHandle");

final closureCallbackThroughHandle = testLibrary.lookupFunction<
    Void Function(Pointer<NativeFunction<Void Function(Handle)>>, Handle),
    void Function(Pointer<NativeFunction<Void Function(Handle)>>,
        Object)>("ClosureCallbackThroughHandle");

final returnHandleInCallback = testLibrary.lookupFunction<
    Handle Function(Pointer<NativeFunction<Handle Function()>>),
    Object Function(
        Pointer<NativeFunction<Handle Function()>>)>("ReturnHandleInCallback");

final handleRecursion = testLibrary.lookupFunction<
    Handle Function(
        Handle, Pointer<NativeFunction<Handle Function(Int64)>>, Int64),
    Object Function(Object, Pointer<NativeFunction<Handle Function(Int64)>>,
        int)>("HandleRecursion");

final propagateErrorWithoutHandle = testLibrary.lookupFunction<
        Int64 Function(Pointer<NativeFunction<Handle Function()>>),
        int Function(Pointer<NativeFunction<Handle Function()>>)>(
    "PropagateErrorWithoutHandle");
