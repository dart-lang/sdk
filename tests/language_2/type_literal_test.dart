// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

import 'type_literal_test.dart' as prefix;

// TODO(rnystrom): This test has a lot of overlap with some other language
// tests, but those are sort of all over the place so I thought it useful to
// test all of the relevant bits in one place here.

class Foo {
  static var property;
  static method() => "result";
}

class Box<T> {
  Type get typeArg => T;
}

typedef int Func(bool b);
typedef int GenericFunc<T>(T t);

main() {
  // Primitive types.
  testType(Object, "Object");
  testType(Null, "Null");
  testType(bool, "bool");
  testType(double, "double");
  testType(int, "int");
  testType(num, "num");
  testType(String, "String");

  // Class types.
  testType(Foo, "Foo");

  // Generic classes.
  testType(Box, "Box");
  testType(new Box<Foo>().typeArg, "Foo");
  testType(new Box<dynamic>().typeArg, "dynamic");
  testType(new Box<Box<Foo>>().typeArg, "Box<Foo>");

  // Typedef.
  testType(Func, "Func");
  testType(GenericFunc, "GenericFunc");
  testType(new Box<GenericFunc<int>>().typeArg, "GenericFunc<int>");

  // Literals are canonicalized.
  Expect.identical(Foo, Foo);
  Expect.identical(Box, Box);
  Expect.identical(new Box<Foo>().typeArg, new Box<Foo>().typeArg);
  Expect.identical(Func, Func);

  // Static member uses are not type literals.
  Foo.property = "value";
  Expect.equals("value", Foo.property);
  Expect.equals("result", Foo.method());

  // Prefixed types are type literals.
  testType(prefix.Foo, "Foo");

  // Prefix member uses are not.
  prefix.Foo.property = "value2";
  Expect.equals("value2", prefix.Foo.property);
  Expect.equals("result", prefix.Foo.method());
}

void testType(Type type, String string) {
  Expect.equals(string, type.toString());
  Expect.isTrue(type is Type);
}
