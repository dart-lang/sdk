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
  factory C8() = C8._;
  C8._() {}
}

class C9 {
  factory C9() = C9._;
  C9._() {}
}
