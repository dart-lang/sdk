// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test of parameterized factory methods.

class Foo<T extends num> {
  Foo();

  factory Foo.bad() = XFoo; // //# 00: compile-time error

  factory Foo.good() = Foo<T>;

  factory Foo.IFoo() {
    return null;
  }
}

abstract class IFoo<T extends num> {
  factory IFoo() = Foo<T>; //# 11: compile-time error
}

// String is not a subtype of num.
class Baz
    extends Foo<String> //# 01: compile-time error
{}

class Biz extends Foo<int> {}

Foo<int> fi;

// String is not a subtype of num.
Foo
    <String> //# 02: compile-time error
    fs;

class Box<T> {
  // Box.T is not guaranteed to be a subtype of num.
  Foo<T> t; //# 03: compile-time error

  makeFoo() {
    // Box.T is not guaranteed to be a subtype of num.
    return new Foo<T>(); //# 04: compile-time error
  }
}

main() {
  // String is not a subtype of num.
  var v1 = new Foo<String>(); //# 05: compile-time error

  // String is not a subtype of num.
  Foo<String> v2 = null; //# 06: compile-time error

  new Baz();
  new Biz();

  fi = new Foo();
  fs = new Foo();

  new Box().makeFoo();
  new Box<int>().makeFoo();
  new Box<String>().makeFoo();

  // Fisk does not exist.
  new Box<Fisk>(); //# 07: compile-time error

  // Too many type arguments.
  new Box<Object, Object>(); //# 08: compile-time error

  // Fisk does not exist.
  Box<Fisk> box = null; //# 09: compile-time error

  // Too many type arguments.
  Box<Object, Object> box = null; //# 10: compile-time error
}
