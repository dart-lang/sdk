// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests `is` checks and `as` casts between various JS objects. Currently, all
// checks and casts should be allowed between JS objects.

@JS()
library is_check_and_as_cast_test;

import 'package:js/js.dart';
import 'package:expect/expect.dart' show hasUnsoundNullSafety;
import 'package:expect/minitest.dart';

@JS()
external void eval(String code);

@JS()
class Foo {
  external Foo(int a);
  external int get a;
}

// Class with same structure as Foo but separate JS class.
@JS()
class Bar {
  external Bar(int a);
  external int get a;
}

@JS('Bar')
class BarCopy {
  external BarCopy(int a);
  external int get a;
}

@JS()
class Baz {
  external Baz(int a, int b);
  external int get a;
  external int get b;
}

// JS object literals
@JS()
@anonymous
class LiteralA {
  external int get x;
}

@JS()
@anonymous
class LiteralB {
  external int get y;
}

// Library is annotated with JS so we don't need the annotation here.
external LiteralA get a;
external LiteralB get b;

class DartClass {}

void main() {
  eval(r"""
    function Foo(a) {
      this.a = a;
    }
    function Bar(a) {
      this.a = a;
    }
    function Baz(a, b) {
      Foo.call(this, a);
      this.b = b;
    }
    Baz.prototype.__proto__ = Foo.prototype;
    var a = {
      x: 1,
    };
    var b = {
      y: 2,
    };
      """);

  // JS class object can be checked and casted with itself.
  var foo = Foo(42);
  expect(foo is Foo, isTrue);
  expect(() => (foo as Foo), returnsNormally);

  // Try it with dynamic.
  dynamic d = Foo(42);
  expect(d is Foo, isTrue);
  expect(() => (d as Foo), returnsNormally);

  // Casts are allowed between any JS class objects.
  expect(foo is Bar, isTrue);
  expect(d is Bar, isTrue);
  expect(() => (foo as Bar), returnsNormally);
  expect(() => (d as Bar), returnsNormally);

  // Type-checking and casting works regardless of the inheritance chain.
  var baz = Baz(42, 43);
  expect(baz is Foo, isTrue);
  expect(() => (baz as Foo), returnsNormally);
  expect(foo is Baz, isTrue);
  expect(() => (foo as Baz), returnsNormally);

  // BarCopy is the same JS class as Bar.
  var barCopy = BarCopy(42);
  expect(barCopy is Bar, isTrue);
  expect(() => (barCopy as Bar), returnsNormally);

  // JS object literal can be checked and casted with itself.
  expect(a is LiteralA, isTrue);
  expect(() => (a as LiteralA), returnsNormally);

  // Like class objects, casts are allowed between any object literals.
  expect(a is LiteralB, isTrue);
  expect(() => (a as LiteralB), returnsNormally);

  // Similarly, casts are allowed between any class objects and object literals.
  expect(foo is LiteralB, isTrue);
  expect(() => (foo as LiteralB), returnsNormally);
  expect(a is Foo, isTrue);
  expect(() => (a as Foo), returnsNormally);

  // You cannot cast between JS interop objects and Dart objects, however.
  var dartClass = DartClass();
  expect(dartClass is Foo, isFalse);
  expect(() => (dartClass as Foo), throws);
  expect(dartClass is LiteralA, isFalse);
  expect(() => (dartClass as LiteralA), throws);

  expect(foo is DartClass, isFalse);
  expect(() => (foo as DartClass), throws);
  expect(a is DartClass, isFalse);
  expect(() => (a as DartClass), throws);

  // Test that nullability is still respected with JS types.
  expect(foo is Foo?, isTrue);
  expect(() => (foo as Foo?), returnsNormally);
  Foo? nullableFoo = null;
  expect(nullableFoo is Foo?, isTrue);
  expect(() => (nullableFoo as Foo?), returnsNormally);
  expect(nullableFoo is Foo, isFalse);
  expect(() => (nullableFoo as Foo),
      hasUnsoundNullSafety ? returnsNormally : throws);

  expect(a is LiteralA?, isTrue);
  expect(() => (a as LiteralA?), returnsNormally);
  LiteralA? nullableA = null;
  expect(nullableA is LiteralA?, isTrue);
  expect(() => (nullableA as LiteralA?), returnsNormally);
  expect(nullableA is LiteralA, isFalse);
  expect(() => (nullableA as LiteralA),
      hasUnsoundNullSafety ? returnsNormally : throws);
}
