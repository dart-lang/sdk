// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for unresolved super[] and super[]= and correct evaluation order.

import "package:expect/expect.dart";

abstract class A {
  var indexField = new List(2);

  operator []=(index, value);
  operator [](index);

  noSuchMethod(Invocation im) {
    if (im.memberName == const Symbol('[]=')) {
      Expect.equals(2, im.positionalArguments.length);
      indexField[im.positionalArguments[0]] = im.positionalArguments[1];
    } else if (im.memberName == const Symbol('[]')) {
      Expect.equals(1, im.positionalArguments.length);
      return indexField[im.positionalArguments[0]];
    } else {
      Expect.fail('Should not reach here');
    }
  }
}

var global = 0;

f() {
  Expect.equals(0, global++);
  return 0;
}

g() {
  Expect.equals(1, global++);
  return 42;
}

class B extends A {
  test() {
    Expect.equals(42, super[f()] = g());
    Expect.equals(2, global);
  }
}

main() {
  new B().test();
}
