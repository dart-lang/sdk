// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library simple_test;

import 'test_base.dart';

class C {}

class A implements C {}

class B extends C {}

class D extends B {}

testIs(o) {
  write(o is A);
  write(o is B);
  write(o is C);
  write(o is D);
}

testIsNot(o) {
  write(o is! A);
  write(o is! B);
  write(o is! C);
  write(o is! D);
}

main() {
  var objects = [new A(), new B(), new C(), new D()];
  objects.forEach(testIs);
  objects.forEach(testIsNot);

  expectOutput("""
true
false
true
false
false
true
true
false
false
false
true
false
false
true
true
true
false
true
false
true
true
false
false
true
true
true
false
true
true
false
false
false""");
}
