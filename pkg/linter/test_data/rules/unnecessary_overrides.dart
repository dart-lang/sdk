// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

class _MyAnnotation {
  const _MyAnnotation();
}

const _MyAnnotation myAnnotation = _MyAnnotation();

class Base {
  int get x => 0;
  set x(other) {}

  int max1(int a, int b) => 0;
  int max2(int a, int b) => 0;
  int m1({int a = 0, int b = 0}) => 0;
  int m2({int a = 0, int b = 0}) => 0;
  int m3({int a = 0, int b = 0}) => 0;
  int m4({int a = 0, int b = 0}) => 0;
  int operator +(other) => 0;
  Base operator ~() => Base();
  @override
  int get hashCode => 13;
}

class Parent extends Base {
  @override
  int get x => super.x; // LINT

  @override
  set x(other)  // LINT
  {
    super.x = other;
  }

  @override
  int max1(int a, int b) => super.max1(a, b); // LINT

  @override
  int max2(int a, int b) => super.max2(b, a); // OK

  @override
  int m1({int a = 0, int b = 0}) => super.m1(a: a, b: b); // LINT

  @override
  int m2({int a = 0, int b = 0}) => super.m2(b: b, a: a); // LINT

  @override
  int m3({int a = 0, int b = 0}) => super.m3(b: a, a: b); // OK

  @override
  int m4({int a = 0, int b = 0}) => super.m1(a: a, b: b); // OK

  @override
  int operator +(other) => super + other; // LINT

  @override
  Base operator ~() => ~super; // LINT

  @override
  @myAnnotation
  int get hashCode => super.hashCode; // OK
}

class Okay extends Parent {
  final a = new Parent();
  @override
  int get x => a.x; // OK

  @override
  set x(other) { // OK
    a.x = other;
  }
}

class NoError extends Okay {
  @override
  int get x => x; // OK

  @override
  set x(other) { // OK
    x = other;
  }
}

class A {
  void foo() {}

  void bar() {}

  int getA(Iterable a) => 0;

  int getB(Iterable a) => 0;

  int getC(Iterable a) => 0;
}

class B extends A {
  @override
  void foo() // LINT
  {
    super.foo();
  }

  @override
  void bar() { // OK
    bar();
  }

  @override
  int getA(Iterable a) => super.getA(a); // LINT

  @override
  int getB(Iterable a) // LINT
  {
    return super.getB(a);
  }

  @override
  int getC(Iterable a) { // OK
    print("something");
    return super.getC(a);
  }
}

class C {
  num get g => 0;
  set s(int v) {}
  @protected
  num m(int v) => 0;
  @protected
  num m1({int v = 20}) => 0;
  num m2([int v = 20]) => 0;
  num operator +(int other) => 0;
}
class ReturnTypeChanged extends C {
  @override
  int get g => super.g as int; // OK
  @override
  int m(int v) => super.m(v) as int; // OK
  @override
  int m1({int v = 20}) => super.m1(v: v) as int; // OK
  @override
  int m2([int v = 20]) => super.m2(v) as int; // OK
  @override
  int operator +(int other) => super + other as int; // OK
}
class ParameterTypeChanged extends C {
  @override
  set s(num v) => super.s = v as int; // OK
  @override
  num m(num v) => super.m(v as int); // OK
  @override
  num m1({num v = 20}) => super.m1(v: v as int); // OK
  @override
  num m2([num v = 20]) => super.m2(v as int); // OK
  @override
  num operator +(num other) => super.g + other; // OK
}
class ParameterNameChanged extends C {
  @override
  set s(num v2) => super.s = v2 as int; // OK
  @override
  num m(int v2) => super.m(v2); // OK
  @override
  num m2([int v2 = 20]) => super.m2(v2); // OK
  @override
  num operator +(int other2) => super + other2; // OK
}
class ParameterCovarianceChanged extends C {
  @override
  set s(covariant int v) => super.s = v; // OK
  @override
  num m(covariant int v) => super.m(v); // OK
  @override
  num m1({covariant int v = 20}) => super.m1(v: v); // OK
  @override
  num m2([covariant int v = 20]) => super.m2(v); // OK
  @override
  num operator +(covariant int other) => super + other; // OK
}
class ParameterAdditional extends C {
  @override
  num m(int v, [int v2 = 1]) => super.m(v); // OK
  @override
  num m1({int v = 20, int? v2}) => super.m1(v: v); // OK
  @override
  num m2([int v = 20, int? v2]) => super.m2(v); // OK
}
class ParameterDefaultChange extends C {
  @override
  num m1({int v = 10}) => super.m1(v: v); // OK
  @override
  num m2([int v = 10]) => super.m2(v); // OK
}
class ProtectedMadePublic extends C {
  @override
  num m(int v) => super.m(v); // OK
  @protected
  num m1({int v = 20}) => super.m1(v: v); // LINT
}

// noSuchMethod is allowed to proxify
class D implements C {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class E extends C {
  /// it's ok to override to provide better documentation
  @override
  num get g => super.g; // OK
}

class F<T> {
  T m1() => throw 42;

  T get g1 => throw 42;

  void set s1(T value) => throw 42;

  T operator +(T other) => throw 42;
}

class G extends F<int> {
  @override
  int m1() => super.m1(); // LINT

  @override
  int get g1 => super.g1; // LINT

  @override
  void set s1(int value) => super.s1 = value; // LINT

  @override
  int operator +(int other) => super + other; // LINT
}

extension on int {
  int m1() => 7;
}
