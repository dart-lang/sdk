// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  final call = null;
}

class B {
  get call => null;
}

class C {
  set call(x) {}
}

typedef int F(String str);

main() {
  A a = new A();
  B b = new B();
  C c = new C();

  final
  Function  /// 00: static type warning, dynamic type error
  a2 = a;

  final
  F  /// 01: static type warning, dynamic type error
  a3 = a;

  final
  Function  /// 02: static type warning, dynamic type error
  b2 = b;

  final
  F  /// 03: static type warning, dynamic type error
  b3 = b;

  final
  Function  /// 04: static type warning, dynamic type error
  c2 = c;

  final
  F  /// 05: static type warning, dynamic type error
  c3 = c;
}
