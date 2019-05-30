// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N prefer_initializing_formals`

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
  num x, y;
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
  num x, y;
  SimpleBadCaseWithOnlyOneLint(this.x, num y) {
    this.y = y; // LINT
  }
}

class SimpleBadCaseWithoutThis {
  num x, y;
  SimpleBadCaseWithoutThis(num a, num b) {
    x = a; // LINT
    y = b; // LINT
  }
}

class SimpleBadCaseWithoutThisAndDifferentDeclarations {
  num x;
  num y;
  SimpleBadCaseWithoutThisAndDifferentDeclarations(num a, num b) {
    x = a; // LINT
    y = b; // LINT
  }
}

class NoFieldsJustSetters {
  String name;
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
  String name;
  NoFieldsJustSettersWithoutThisAndWithOneGetter(num a, num b) {
    x = a; // OK
    y = b; // OK
  }
  get x {
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
  num r, theta;
  SuperCallWithConstructorParameters(num r, num theta)
      : super(r * cos(theta), r * sin(theta)) {
    this.r = r; // LINT
    this.theta = theta; // LINT
  }
}

class BadCaseWithNamedConstructorAndInitializerLint {
  num x, y;
  BadCaseWithNamedConstructorAndInitializerLint.lint1(num a, this.y)
      : this.x = a, // LINT
        super();
  BadCaseWithNamedConstructorAndInitializerLint.lint2(num a, this.y)
      : x = a, // LINT
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
  num _x, _y;
  GoodCaseWithPrivateFields(num x, num y) {
    this._x = x; // OK // This should be lint for other rule
    this._y = y; // OK // This should be lint for other rule
  }
}

class GoodCaseWithPrivateFieldsWithoutThis {
  // ignore: unused_field
  num _x, _y;
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
  num x, y;
  BadCaseWithTwoFieldsOneArgument(num x) {
    this.x = x; // LINT
    this.y = x; // OK
  }
}

class GoodCaseWithTwoFieldsOneArgument {
  num x, y;
  GoodCaseWithTwoFieldsOneArgument(this.x) {
    y = this.x; // OK
  }
}

class GoodCaseWithTwoFieldsOneArgumentWithoutThis {
  num x, y;
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
  num x, y;
  BadCaseWithNamedArgs({num x, num y = 1}) {
    this.x = x; // LINT
    this.y = y; // LINT
  }
}

class GoodCaseWithDifferentNamedArgs {
  num x, y;
  GoodCaseWithDifferentNamedArgs({num a, num b = 1}) {
    this.x = a; // OK
    this.y = b; // OK
  }
}

class BadCaseWithNamedArgsInitializer {
  num x, y;
  BadCaseWithNamedArgsInitializer({num x, num y = 1})
      : this.x = x, // LINT
        this.y = y; // LINT
}

class GoodCaseWithDifferentNamedArgsInitializer {
  num x, y;
  GoodCaseWithDifferentNamedArgsInitializer({num a, num b = 1})
      : this.x = a, // OK
        this.y = b; // OK
}
