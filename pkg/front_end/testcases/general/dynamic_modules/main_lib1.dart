// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C1 {
  C1();
  void method1() {}
  int get getter1 => 1;
  set setter1(int value) {}
  static void method2() {}
  static int get getter2 => 1;
  static set setter2(int value) {}
  int field1 = 2;
  static int field2 = 3;
}

class C2 {
  C2();
  void method1() {}
  int get getter1 => 1;
  set setter1(int value) {}
  static void method2() {}
  static int get getter2 => 1;
  static set setter2(int value) {}
  int field1 = 2;
  static int field2 = 3;
}

class C3 {}

abstract class C4 {
  void method1();
  void method2();
  int? field1;
  int? field2;
}

mixin M1 {}
mixin M2 {}

void method1() {}
void method2() {}

int field1 = 4;
int field2 = 4;

class Base {
  void foo() {}
}

abstract class Interface {
  void foo();
}

mixin Mixin {
  void foo() {}
}

class _C5 {
  const _C5(this.func);
  final Function func;
}

void _privateMethod1() {}
void _privateMethod2() {}

const const1 = _C5(_privateMethod1);
const const2 = _C5(_privateMethod2);

class _ConstForC6 {
  const _ConstForC6(this._f);
  final Function _f;
}

void _privateMethodForC6() {}

class C6 {
  C6({Object param = const _ConstForC6(_privateMethodForC6)});
}

class _ConstForC7 {
  const _ConstForC7(this._f);
  final Function _f;
}

void _privateMethodForC7() {}

class C7 {
  C7({Object param = const _ConstForC7(_privateMethodForC7)});
}

class C8 {
  factory C8.fact1() = C8;
  factory C8.fact2() = C8.fact3;
  factory C8.fact3() => C8();
  C8() {}
  const factory C8.fact4() = C8.constConstr;
  const C8.constConstr();
}

class C9 {
  factory C9.fact1() = C9;
  factory C9.fact2() = C9.fact3;
  factory C9.fact3() => C9();
  C9() {}
  const factory C9.fact4() = C9.constConstr;
  const C9.constConstr();
}

extension type ExtType1(int raw) {}

extension Ext1 on int {
  bool get isPositive => this > 0;
}

extension type ExtType2(int raw) {
  bool get isPositive => raw > 0;
}

extension type ExtType3(int raw) {
  bool get isPositive => raw > 0;
}

extension type ExtType4(int raw) {
  bool get isPositive => raw > 0;
}

extension type ExtType5._(int raw) {
  ExtType5.plus1(int n) : this._(n + 1);
  bool get isPositive => raw > 0;
}
