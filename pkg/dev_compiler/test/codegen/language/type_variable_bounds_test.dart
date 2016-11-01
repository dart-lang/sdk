// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test of parameterized factory methods.

class Foo<T extends num> {
  Foo();

  factory Foo.bad() = XFoo;  /// 00: static type warning

  factory Foo.good() = Foo;

  factory Foo.IFoo() { return null; }
}

abstract class IFoo<T extends num> {
  factory IFoo() = Foo<T>;
}

// String is not assignable to num.
class Baz
    extends Foo<String> /// 01: static type warning, dynamic type error
{}

class Biz extends Foo<int> {}

Foo<int> fi;

// String is not assignable to num.
Foo
    <String> /// 02: static type warning, dynamic type error
  fs;

class Box<T> {

  // Box.T is not assignable to num.
  Foo<T> t; /// 03: static type warning

  makeFoo() {
    // Box.T is not assignable to num.
    return new Foo<T>(); /// 04: static type warning, dynamic type error
  }
}

main() {
  // String is not assignable to num.
  var v1 = new Foo<String>(); /// 05: static type warning, dynamic type error

  // String is not assignable to num.
  Foo<String> v2 = null; /// 06: static type warning

  new Baz();
  new Biz();

  fi = new Foo();
  fs = new Foo();

  new Box().makeFoo();
  new Box<int>().makeFoo();
  new Box<String>().makeFoo();

  // Fisk does not exist.
  new Box<Fisk>(); /// 07: static type warning

  // Too many type arguments.
  new Box<Object, Object>(); /// 08: static type warning

  // Fisk does not exist.
  Box<Fisk> box = null; /// 09: static type warning

  // Too many type arguments.
  Box<Object, Object> box = null; /// 10: static type warning
}
