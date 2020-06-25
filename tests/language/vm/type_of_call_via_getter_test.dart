// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that compiler infers correct type from call via getter.

// VMOptions=--no_background_compilation --optimization_counter_threshold=10

import "package:expect/expect.dart";

typedef String IntFunctionType(int _);

String functionImpl(int a) => 'abc';

class Box {
  IntFunctionType get fun => functionImpl;
}

var box = new Box();

void test1() {
  Expect.isFalse(box.fun(42) is Function);
  Expect.isTrue(box.fun(42) is String);
}

class Callable {
  String call(int i) => 'qwe';
}

class Box2 {
  Callable get fun => new Callable();
}

var box2 = new Box2();

void test2() {
  Expect.isFalse(box2.fun is Function);
  Expect.isTrue(box2.fun is Callable);
  Expect.isFalse(box2.fun(42) is Function);
  Expect.isFalse(box2.fun(42) is Callable);
  Expect.isTrue(box2.fun(42) is String);
}

void main() {
  for (int i = 0; i < 20; ++i) {
    test1();
  }
  for (int i = 0; i < 20; ++i) {
    test2();
  }
}
