// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension A on C {
  void method() {}
  int get getter => 42;
  void set setter(int value) {}
  int get property => 42;
  int operator +(int i) => i;
  int operator -() => 0;
  int operator [](int i) => i;
}

extension B on C {
  void method() {}
  int get getter => 42;
  void set setter(int value) {}
  void set property(int value) {}
  int operator +(int i) => i;
  int operator -() => 0;
  void operator []=(int i, int j) {}
}

class C {}

errors(C c) {
  c.method();
  c.method;
  c.getter;
  c.setter;
  c.getter = 42;
  c.setter = 42;
  c.property;
  c.property = 42;
  c + 0;
  -c;
  c[42];
  c[42] = 0;
}

main() {}
