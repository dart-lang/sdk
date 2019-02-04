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

class G<A, B> {}

/// A typedef that defines a non-generic function type.
typedef int Func(bool b);

/// Semantically identical to [Func], but using the Dart 2 syntax.
typedef Func2 = int Function(bool);

/// A typedef that defines a generic function type.
typedef GenericFunc = int Function<T>(T);

/// A typedef with a type paramter that defines a non-generic function type.
typedef int GenericTypedef<T>(T t);

/// Semantically identical to [GenericTypedef], but using the Dart 2 syntax.
typedef GenericTypedef2<T> = int Function(T);

/// A typedef with a type paramter that defines a generic function type.
typedef GenericTypedefAndFunc<S> = S Function<T>(T);

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
  testType(Box, ["Box", "Box<dynamic>"]);
  testType(new Box<Foo>().typeArg, "Foo");
  testType(new Box<dynamic>().typeArg, "dynamic");
  testType(new Box<Box<Foo>>().typeArg, "Box<Foo>");
  testType(G, ["G", "G<dynamic, dynamic>"]);
  testType(new Box<G<int, String>>().typeArg, "G<int, String>");

  // Typedef.
  testType(Func, ["Func", "(bool) => int"]);
  testType(Func2, ["Func2", "(bool) => int"]);
  testType(GenericTypedef,
      ["GenericTypedef", "GenericTypedef<dynamic>", "(dynamic) => int"]);
  testType(GenericTypedef2,
      ["GenericTypedef2", "GenericTypedef2<dynamic>", "(dynamic) => int"]);
  testType(new Box<GenericTypedef<int>>().typeArg,
      ["GenericTypedef<int>", "(int) => int"]);
  testType(GenericFunc, ["GenericFunc", "<T>(T) => int"]);
  testType(GenericTypedefAndFunc, [
    "GenericTypedefAndFunc",
    "GenericTypedefAndFunc<dynamic>",
    "<T>(T) => dynamic"
  ]);

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

void testType(Type type, Object expectedToStringValues) {
  if (expectedToStringValues is List) {
    var s = type.toString();
    Expect.isTrue(expectedToStringValues.contains(s),
        'type `$type`.toString() should be one of: $expectedToStringValues.');
  } else {
    var string = expectedToStringValues as String;
    Expect.equals(string, type.toString());
  }
  Expect.isTrue(type is Type);
}
