// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

String test1(Object x) => switch (x) {
  String s => s,
  int i => "$i",
  _ => throw ArgumentError(),
};

abstract class A {
  Object get x;
}

abstract class B {
  A get a;
}

void test2(B obj) {
  if (obj.a.x case [String path]) {
    print(path);
  }
}

abstract class C {
  D get d;
}

abstract class D {
  List<String>? operator [](String name);
}

void test3(C obj) {
  if (obj.d['foo'] case [String path]) {
    print(path);
  }
}

void main() {}
