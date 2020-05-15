// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test that it is possible to invoke an object whose type is a proper subtype
// of a function type (that is, its type is 'function-type bounded', and we
// get to call it as if its type had been that bound).

class A<X, Y extends X Function(X)> {
  final Y f;
  A(this.f);
  X m(X value) => f(value);
}

class B extends A<String, String Function(String, {int i})> {
  B(String Function(String, {int i}) f) : super(f);
  String m(String value) => f(value, i: 42);
}

void main() {
  B b = B((String s, {int i}) => "$s and $i");
  Expect.equals('24 and 42', b.m('24'));
}
