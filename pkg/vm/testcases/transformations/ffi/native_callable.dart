// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

void main() {
  testNativeCallableListener();
  testNativeCallableListenerClosure();
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
