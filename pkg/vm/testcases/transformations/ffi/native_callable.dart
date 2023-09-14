// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

void main() {
  testNativeCallableListener();
  testNativeCallableListenerClosure();
  testNativeCallableIsolateLocalVoid();
  testNativeCallableIsolateLocalVoidClosure();
  testNativeCallableIsolateLocalPointer();
  testNativeCallableIsolateLocalPointerClosure();
  testNativeCallableIsolateLocalInt();
  testNativeCallableIsolateLocalIntClosure();
}

void printInt(int i) => print(i);

void testNativeCallableListener() {
  final callback = NativeCallable<Void Function(Int32)>.listener(printInt);
  print(callback.nativeFunction);
  callback.close();
}

void testNativeCallableListenerClosure() {
  int j = 123;
  void closure(int i) => print(i + j);
  final callback = NativeCallable<Void Function(Int32)>.listener(closure);
  print(callback.nativeFunction);
  callback.close();
}

void testNativeCallableIsolateLocalVoid() {
  final callback = NativeCallable<Void Function(Int32)>.isolateLocal(printInt);
  print(callback.nativeFunction);
  callback.close();
}

void testNativeCallableIsolateLocalVoidClosure() {
  int j = 123;
  void closure(int i) => print(i + j);
  final callback = NativeCallable<Void Function(Int32)>.isolateLocal(closure);
  print(callback.nativeFunction);
  callback.close();
}

Pointer intToPointer(int i) => Pointer.fromAddress(i);

void testNativeCallableIsolateLocalPointer() {
  final callback =
      NativeCallable<Pointer Function(Int32)>.isolateLocal(intToPointer);
  print(callback.nativeFunction);
  callback.close();
}

void testNativeCallableIsolateLocalPointerClosure() {
  int j = 123;
  Pointer closure(int i) => Pointer.fromAddress(i + j);
  final callback =
      NativeCallable<Pointer Function(Int32)>.isolateLocal(closure);
  print(callback.nativeFunction);
  callback.close();
}

int negateInt(int i) => -i;

void testNativeCallableIsolateLocalInt() {
  final callback = NativeCallable<Int Function(Int32)>.isolateLocal(negateInt,
      exceptionalReturn: 123);
  print(callback.nativeFunction);
  callback.close();
}

void testNativeCallableIsolateLocalIntClosure() {
  int j = 123;
  int closure(int i) => i + j;
  final callback = NativeCallable<Int Function(Int32)>.isolateLocal(closure,
      exceptionalReturn: 123);
  print(callback.nativeFunction);
  callback.close();
}
