// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  int? field;
  int? getter => null;
  void setter(int? value) {}
  void method() {}
}

test(Class c, dynamic d, Function f1, void Function() f2) {
  c.field = c.field;
  c.setter = c.getter;
  c.method;
  c.method();
  d.field = d.field;
  d.setter = d.getter;
  d.method;
  d.method();
  f1();
  f1.call;
  f2();
  f2.call;
  local() {}
  local();
  c == d;
  c != d;
  c == null;
  c != null;
  d == null;
  d != null;
}

main() {}
