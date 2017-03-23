// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that both `=` and `:` are allowed for named parameters.

import "package:expect/expect.dart";

// Default values are not allowed on typedefs.
typedef int F1({x = 3, y}); //# 01: compile-time error

typedef int functype({x, y, z});

int topF({x = 3, y: 5, z}) => x * y * (z ?? 2);

class A {
  int x;
  int y;
  int z;
  A({this.x = 3, this.y: 5, z}) : z = z ?? 2;
  A.redirect({x = 3, y: 5, z}) : this(x: x, y: y, z: z);
  factory A.factory({x = 3, y: 5, z}) => new A(x: x, y: y, z: z ?? 2);
  factory A.redirectFactory({x, y, z}) = A;

  // Default values are not allowed on redirecting factory constructors.
  factory A.badRedirectFactory({x = 3, y}) = A; //# 02: compile-time error

  int get value => x * y * z;

  static int staticF({x = 3, y: 5, z}) => x * y * (z ?? 2);
  int instanceF({x = 3, y: 5, z}) => x * y * (z ?? 2);
}

main() {
  // Reference the type, or dart2js won't see that the declaration is invalid
  F1 _ = null; // //# 01: continued

  var a = new A();

  int local({x = 3, y: 5, z}) => x * y * (z ?? 2);
  var expr = ({x = 3, y: 5, z}) => x * y * (z ?? 2);
  var tearOff = a.instanceF;

  test(function) {
    Expect.equals(30, function());
    Expect.equals(70, function(x: 7));
    Expect.equals(42, function(y: 7));
    Expect.equals(28, function(x: 7, y: 2));
    Expect.equals(15, function(z: 1));
    Expect.equals(21, function(y: 7, z: 1));
    Expect.equals(35, function(x: 7, z: 1));
    Expect.equals(14, function(x: 7, y: 2, z: 1));
    Expect.isTrue(function is functype);
  }

  test(topF);
  test(A.staticF);
  test(a.instanceF);
  test(local);
  test(expr);
  test(tearOff);

  // Can't tear off constructors.
  Expect.equals(30, new A().value);
  Expect.equals(70, new A(x: 7).value);
  Expect.equals(42, new A(y: 7).value);
  Expect.equals(28, new A(x: 7, y: 2).value);
  Expect.equals(15, new A(z: 1).value);
  Expect.equals(21, new A(y: 7, z: 1).value);
  Expect.equals(35, new A(x: 7, z: 1).value);
  Expect.equals(14, new A(x: 7, y: 2, z: 1).value);

  Expect.equals(30, new A.redirect().value);
  Expect.equals(70, new A.redirect(x: 7).value);
  Expect.equals(42, new A.redirect(y: 7).value);
  Expect.equals(28, new A.redirect(x: 7, y: 2).value);
  Expect.equals(15, new A.redirect(z: 1).value);
  Expect.equals(21, new A.redirect(y: 7, z: 1).value);
  Expect.equals(35, new A.redirect(x: 7, z: 1).value);
  Expect.equals(14, new A.redirect(x: 7, y: 2, z: 1).value);

  Expect.equals(30, new A.factory().value);
  Expect.equals(70, new A.factory(x: 7).value);
  Expect.equals(42, new A.factory(y: 7).value);
  Expect.equals(28, new A.factory(x: 7, y: 2).value);
  Expect.equals(15, new A.factory(z: 1).value);
  Expect.equals(21, new A.factory(y: 7, z: 1).value);
  Expect.equals(35, new A.factory(x: 7, z: 1).value);
  Expect.equals(14, new A.factory(x: 7, y: 2, z: 1).value);

  Expect.equals(30, new A.redirectFactory().value);
  Expect.equals(70, new A.redirectFactory(x: 7).value);
  Expect.equals(42, new A.redirectFactory(y: 7).value);
  Expect.equals(28, new A.redirectFactory(x: 7, y: 2).value);
  Expect.equals(15, new A.redirectFactory(z: 1).value);
  Expect.equals(21, new A.redirectFactory(y: 7, z: 1).value);
  Expect.equals(35, new A.redirectFactory(x: 7, z: 1).value);
  Expect.equals(14, new A.redirectFactory(x: 7, y: 2, z: 1).value);
}
