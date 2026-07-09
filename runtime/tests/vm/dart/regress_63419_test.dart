// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/63419.

// VMOptions=--compiler-passes=-Inlining

import 'package:expect/expect.dart';

abstract interface class Box1<T> {
  T get x;
  void set x(T value);
}

class StringBox implements Box1<String> {
  @pragma("vm:never-inline")
  String x = 'yay';
}

abstract interface class Box2<T> {
  T get x;
  void set x(T value);
}

class IntBox implements Box2<int> {
  @pragma("vm:never-inline")
  int x = 0;
}

void main() {
  final Box1<Object> box1 = StringBox();
  box1.x = 'xyz';
  Expect.equals('xyz', box1.x);
  Expect.throws(() {
    box1.x = 123;
  });

  final Box2<Object> box2 = IntBox();
  box2.x = 123;
  Expect.equals(123, box2.x);
  Expect.throws(() {
    box2.x = 'abc';
  });
}
