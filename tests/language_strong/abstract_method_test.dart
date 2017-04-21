// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Checks that abstract instance methods are correctly resolved.

int get length => throw "error: top-level getter called";
set height(x) {
  throw "error: top-level setter called";
}

width() {
  throw "error: top-level function called";
}

abstract class A {
  int get length; //    Abstract instance getter.
  set height(int x); // Abstract instance setter.
  int width(); //       Abstract instance method.

  // Must resolve to non-abstract length getter in subclass.
  get useLength => length;
  // Must resolve to non-abstract height setter in subclass.
  setHeight(x) => height = x;
  // Must resolve to non-abstract width() method in subclass.
  useWidth() => width();
}

class A1 extends A {
  int length; // Implies a length getter.
  int height; // Implies a height setter.
  int width() => 345;
  A1(this.length);
}

main() {
  var a = new A1(123);
  Expect.equals(123, a.useLength);
  a.setHeight(234);
  Expect.equals(234, a.height);
  Expect.equals(345, a.useWidth());
  print([a.useLength, a.height, a.useWidth()]);
}
