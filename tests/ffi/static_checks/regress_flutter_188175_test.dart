// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Repro for https://github.com/flutter/flutter/issues/188175.

import 'dart:ffi';

abstract class MyInterface {
  void myMethod();
}

// dart format off
class MyClass implements MyInterface {
//    ^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER
// [cfe] The non-abstract class 'MyClass' is missing implementations for these members:
}
// dart format on

class Wrapper<T extends MyInterface> {
  final T client;
  Wrapper(this.client);

  void register() {
    NativeCallable<Void Function()>.listener(client.myMethod);
  }
}

void main() {
  final w = Wrapper<MyClass>(MyClass());
  w.register();
}
