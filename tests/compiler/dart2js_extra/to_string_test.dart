// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A extends Object {
}

class Adder {
  final x;
  final y;
  Adder(x, y) : this.x = x, this.y = y;
  add() => x + y;
}

test(expected, x) {
  Expect.equals(expected, x.toString());
  Expect.equals(expected, new Adder("", x).add());
}

main() {
  test("Instance of 'Object'", new Object());
  test("Instance of 'A'", new A());
  test("[]", []);
  test("1", 1);
}
