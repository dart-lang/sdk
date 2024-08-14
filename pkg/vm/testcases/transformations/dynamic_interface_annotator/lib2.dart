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

class _E1 {
  final int _x;
  const _E1(this._x);
}

class _E2 extends _E1 {
  final int _y;
  const _E2(super._x, this._y);
}

mixin H {
  void foo() {
    _foo();
  }

  void _foo() {
    _smethod12();
  }

  static void _smethod12() {
    _smethod13();
  }
}

void _smethod13() {}

class _I1<T> {}

class _I2 {}

class _I3 {}

mixin class J implements _I1<_I2> {
  static const _const14 = {'key': _E2(3, 4)};
  static int _smethod15() => 42;

  var _ifield16 = _const14;
  var _ifield17 = _smethod15();
  _I3? _ifield18;
}
