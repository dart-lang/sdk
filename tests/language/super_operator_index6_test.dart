// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for unresolved super[].

import "package:expect/expect.dart";

class A {
  var indexField = new List(2);
  operator []=(index, value) {
    indexField[index] = value;
  }

  noSuchMethod(Invocation im) {
    if (im.memberName == const Symbol('[]')) {
      Expect.equals(1, im.positionalArguments.length);
      return indexField[im.positionalArguments[0]];
    } else {
      Expect.fail('Should not reach here');
    }
  }
}

class B extends A {
  test() {
    Expect.equals(42, super[0] = 42);
    Expect.equals(42, super[0]);
    Expect.equals(43, super[0] += 1);
    Expect.equals(43, super[0]);
    Expect.equals(43, super[0]++);
    Expect.equals(44, super[0]);

    Expect.equals(2, super[0] = 2);
    Expect.equals(2, super[0]);
    Expect.equals(3, super[0] += 1);
    Expect.equals(3, super[0]);
    Expect.equals(3, super[0]++);
    Expect.equals(4, super[0]);
  }
}

main() {
  new B().test();
}
