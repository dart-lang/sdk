// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

class C {
  var f = () => "f";
  get g => (x) => "g($x)";
  a() => "a";
  b(x) => x;
  c(x, [y = 2]) => x + y;
  d(x, {y: 2}) => x + y;
}

/// This class doesn't use its type variable.
class D<T> {
  var f = () => "f";
  get g => (x) => "g($x)";
  a() => "a";
  b(x) => x;
  c(x, [y = 2]) => x + y;
  d(x, {y: 2}) => x + y;
}

/// This class uses its type variable.
class E<T> {
  var f = () => "f";
  get g => (T x) => "g($x)";
  a() => "a";
  b(T x) => x;
  c(T x, [T y = 2]) => x + y;
  d(T x, {T y: 2}) => x + y;
}

expect(expected, actual) {
  print("Expecting '$expected' and got '$actual'");
  if (expected != actual) {
    print("Expected '$expected' but got '$actual'");
    throw "Expected '$expected' but got '$actual'";
  }
}

test(o) {
  expect("f", o.f());
  expect("f", (o.f)());
  expect("g(42)", o.g(42));
  expect("g(42)", (o.g)(42));
  expect("a", o.a());
  expect("a", (o.a)());
  expect(42, o.b(42));
  expect(42, (o.b)(42));
  expect(42, o.c(40));
  expect(42, (o.c)(40));
  expect(87, o.c(80, 7));
  expect(87, (o.c)(80, 7));
  expect(42, o.d(40));
  expect(42, (o.d)(40));
  expect(87, o.d(80, y: 7));
  expect(87, (o.d)(80, y: 7));
}

main(arguments) {
  test(new C());
  test(new D<int>());
  test(new E<int>());
}
