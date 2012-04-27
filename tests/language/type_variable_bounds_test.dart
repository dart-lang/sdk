// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test of parameterized factory methods.

class Foo<T extends num> {
  Foo();

  factory XFoo.bad() { return null; } /// 00: compile-time error

  factory IFoo.good() { return null; }

  factory IFoo() { return null; }
}

interface IFoo<T extends num> default Foo<T extends num> {
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
    return new Foo<T>(); /// 04: static type warning
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
  new Box<Fisk>(); /// 07: compile-time error

  // Too many type arguments.
  new Box<Object, Object>(); /// 08: compile-time error

  // Fisk does not exist.
  Box<Fisk> box = null; /// 09: static type warning

  // Too many type arguments.
  Box<Object, Object> box = null; /// 10: static type warning
}
