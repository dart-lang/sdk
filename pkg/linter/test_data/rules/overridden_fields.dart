// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `dart test -N overridden_fields`

class Base {
  Object field = 'lorem';

  Object something = 'change';
}

mixin BaseMixin {
  Object something = 'change';
}

class Bad1 extends Base {
  final x = 1, field = 'ipsum'; // LINT
}

class Bad2 extends Base {
  @override
  Object something = 'done'; // LINT
}

class Bad3 extends Object with BaseMixin {
  @override
  Object something = 'done'; // LINT
}

class Ok extends Base {
  Object newField = 0; // OK

  final Object newFinal = 'ignore'; // OK
}

class OK2 implements Base {
  @override
  Object something = 'done'; // OK

  @override
  Object field = 0;
}

abstract class OK3 implements Base {
  @override
  Object something = 'done'; // OK
}

class GC11 extends Bad1 {
  @override
  Object something = 'done'; // LINT

  Object gc33 = 'gc33';
}

abstract class GC12 implements Bad1 {
  @override
  Object something = 'done'; // OK
}

abstract class GC22 implements GC11 {
  @override
  Object something = 'done'; // OK
}

class Super1 {}

class Sub1 extends Super1 {
  int y = 0;
}

class Super2 {
  int x = 0, y = 0;
}

class Sub2 extends Super2 {
  @override
  int y = 0; // LINT
}

class Super3 {
  int x = 0;
}

class Sub3 extends Super3 {
  int x = 0; // LINT
}

class A1 {
  int f = 0;
}

class B1 extends A1 {}

abstract class C1 implements A1 {}

class D1 extends B1 implements C1 {
  @override
  int f = 0; // LINT
}

class StaticsNo {
  static int a = 0;
}

class VerifyStatic extends StaticsNo {
  static int a = 0;
}

mixin M on A1 {
  @override
  int f = 0; // LINT

  int g = 0; // OK
}

abstract class BB {
  abstract String s;
}

mixin AbstractMixin {
  abstract String s;
}

class AA extends BB {
  /// Overriding abstracts in NNBD is OK.
  @override
  String s = ''; // OK
}

class AAA with AbstractMixin {
  @override
  String s = ''; // OK
}

abstract class BBB {
  abstract final String s;
}

class AAAA extends BBB {
  @override
  String s = ''; // OK
}