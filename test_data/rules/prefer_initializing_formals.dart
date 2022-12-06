// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `dart test -N prefer_initializing_formals`

class D {
  /// https://github.com/dart-lang/linter/issues/2664
  D(int initialValue) : value = initialValue;

  int? value;
}

class C {
  String? value;
  C._();

  /// https://github.com/dart-lang/linter/issues/2441
  factory C.withValue(String? value) {
    var c = C._();
    c.value = value; // OK
    return c;
  }
}

class Foo {
  final bool isBlahEnabled;
  final List<String> whatever;

  /// https://github.com/dart-lang/linter/issues/2605
  Foo(bool isThingEnabled)
      : whatever = isThingEnabled ? ['thingstuff'] : ['otherstuff'],
        isBlahEnabled = isThingEnabled; // OK
}

class A {
  int x;
  A(this.x);
}

class B extends A {
  B(int y) : super(y) {
    x = y; // OK
  }
}

num cos(num theta) {
  return 0;
}

num sin(num theta) {
  return 0;
}

class SimpleBadCase {
  num x = 0, y = 0;
  SimpleBadCase(num x, num y) {
    this.x = x; // LINT
    this.y = y; // LINT
  }
}

class SimpleGoodCase {
  num x, y;
  SimpleGoodCase(this.x, this.y);
}

class SimpleBadCaseWithOnlyOneLint {
  num x, y = 0;
  SimpleBadCaseWithOnlyOneLint(this.x, num y) {
    this.y = y; // LINT
  }
}

/// https://github.com/dart-lang/linter/issues/2605
class RenamedFieldsForReadability {
  num x = 0, y = 0;
  RenamedFieldsForReadability(num a, num b) {
    x = a; // OK
    y = b; // OK
  }
}

/// https://github.com/dart-lang/linter/issues/2605
class RenamedFieldsForReadability2 {
  num x = 0;
  num y = 0;
  RenamedFieldsForReadability2(num a, num b) {
    x = a; // OK
    y = b; // OK
  }
}

class NoFieldsJustSetters {
  String name = '';
  NoFieldsJustSetters(num x, num y) {
    this.x = x; // OK
    this.y = y; // OK
  }
  set x(num x) {
    name = 'My x value is $x';
  }

  set y(num y) {
    name = 'My y value is $y';
  }
}

class NoFieldsJustSettersWithoutThisAndWithOneGetter {
  String name = '';
  NoFieldsJustSettersWithoutThisAndWithOneGetter(num a, num b) {
    x = a; // OK
    y = b; // OK
  }
  num get x {
    return 0;
  }

  set x(num x) {
    name = 'My x value is $x';
  }

  set y(num y) {
    name = 'My y value is $y';
  }
}

class SuperCallWithConstructorParameters extends SimpleGoodCase {
  num r = 0, theta = 0;
  SuperCallWithConstructorParameters(num r, num theta)
      : super(r * cos(theta), r * sin(theta)) {
    this.r = r; // LINT
    this.theta = theta; // LINT
  }
}

class NamedConstructorRenameAndInitializer {
  num x, y;
  NamedConstructorRenameAndInitializer.ok1(num a, this.y)
      : this.x = a, // OK
        super();
  NamedConstructorRenameAndInitializer.ok2(num a, this.y)
      : x = a, // OK
        super();
}

class BadCaseWithNamedConstructorAndSuperCall extends SimpleGoodCase {
  num r, theta;
  BadCaseWithNamedConstructorAndSuperCall.ok(num r, num theta)
      : this.r = r, // LINT
        this.theta = theta, // LINT
        super(r * cos(theta), r * sin(theta));
}

class GoodCaseWithPrivateFields {
  // ignore: unused_field
  num? _x, _y;
  GoodCaseWithPrivateFields(num x, num y) {
    this._x = x; // OK // This should be lint for other rule
    this._y = y; // OK // This should be lint for other rule
  }
}

class GoodCaseWithPrivateFieldsWithoutThis {
  // ignore: unused_field
  num _x = 0, _y = 0;
  GoodCaseWithPrivateFieldsWithoutThis(num x, num y) {
    _x = x; // OK // This should be lint for other rule
    _y = y; // OK // This should be lint for other rule
  }
}

class GoodCaseWithPrivateFieldsInInitializers {
  // ignore: unused_field
  final num _x, _y;
  GoodCaseWithPrivateFieldsInInitializers(num x, num y)
      : this._x = x, // OK // This is the right way to do
        this._y = y; // OK // This is the right way to do
}

class GoodCaseWithPrivateFieldsInInitializersWithoutThis {
  // ignore: unused_field
  final num _x, _y;
  GoodCaseWithPrivateFieldsInInitializersWithoutThis(num x, num y)
      : _x = x, // OK // This is the right way to do
        _y = y; // OK // This is the right way to do
}

class BadCaseWithTwoFieldsOneArgument {
  num x = 0, y = 0;
  BadCaseWithTwoFieldsOneArgument(num x) {
    this.x = x; // LINT
    this.y = x; // OK
  }
}

class GoodCaseWithTwoFieldsOneArgument {
  num x = 0, y = 0;
  GoodCaseWithTwoFieldsOneArgument(this.x) {
    y = this.x; // OK
  }
}

class GoodCaseWithTwoFieldsOneArgumentWithoutThis {
  num x = 0, y = 0;
  GoodCaseWithTwoFieldsOneArgumentWithoutThis(this.x) {
    y = x; // OK
  }
}

class BadCaseWithOneParameterToTwoFields {
  final int a, b;

  BadCaseWithOneParameterToTwoFields(int b)
      : a = b, // OK
        this.b = b; // LINT
}

class GoodCaseWithOneParameterToTwoFields {
  final int a, b;

  GoodCaseWithOneParameterToTwoFields(this.b) : a = b; // OK
}

class GoodCaseWithOneParameterToTwoFieldsBecauseTheyHaveDifferentNames {
  final int a, b;

  GoodCaseWithOneParameterToTwoFieldsBecauseTheyHaveDifferentNames(int c)
      : a = c, // OK
        b = c; // OK
}

class BadCaseWithNamedArgs {
  num? x, y;
  BadCaseWithNamedArgs({num? x, num y = 1}) {
    this.x = x; // LINT
    this.y = y; // LINT
  }
}

class GoodCaseWithDifferentNamedArgs {
  num? x, y;
  GoodCaseWithDifferentNamedArgs({num? a, num b = 1}) {
    this.x = a; // OK
    this.y = b; // OK
  }
}

class BadCaseWithNamedArgsInitializer {
  num? x, y;
  BadCaseWithNamedArgsInitializer({num? x, num y = 1})
      : this.x = x, // LINT
        this.y = y; // LINT
}

class GoodCaseWithDifferentNamedArgsInitializer {
  num? x, y;
  GoodCaseWithDifferentNamedArgsInitializer({num? a, num b = 1})
      : this.x = a, // OK
        this.y = b; // OK
}
