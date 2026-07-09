// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A {
  A();
  A._();
  factory A.factory1() = B;
  factory A.factory2() => B();
  factory A._factory3() => B();
  Object? ifield1;
  Object? _ifield2;
  static Object? sfield3;
  static Object? _sfield4;
  void imethod1() {}
  void imethod2();
  void _imethod3() {}
  static void smethod4() {}
}

class B extends A {
  B();
  Object? ifield5;
  Object? _ifield6;
  void imethod2() {}
  void imethod5() {}
  void _imethod6() {}
  static void smethod7() {}
}

class _C {
  Object? ifield7;
  static Object? _sfield8;
  void imethod8() {}
  static void smethod9() {}
}

class D {
  void build() {}
}

Object? sfield9;
Object? _sfield10;
void smethod10() {}
void _smethod11() {}
