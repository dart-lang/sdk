// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C<T> {
}

extension ext<T> on C<T> {
  int field;

  final int property = 42;

  void set property(int value) {}

  final int property2 = 42;

  static void set property2(int value) {}

  method() {
    field;
    field = 23;
    property;
    property = 23;
    property2;
    property2 = 23;
  }
}

main() {
}

errors() {
  C<int> c = new C<int>();
  c.field;
  c.field = 23;
  c.property;
  c.property = 23;
  c.property2;
  c.property2 = 23;
  ext(c).field;
  ext(c).field = 23;
  ext(c).property;
  ext(c).property = 23;
  ext(c).property2;
  ext(c).property2 = 23;
  c.method();
}