// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {}

class B extends A {
  static Object returnValue;
  static Object argument;
  Object operator +(Object x) {
    argument = x;
    return returnValue;
  }
}

void main() {
  B origB = new B();
  B b = origB;
  B.returnValue = new B();
  B.argument = null;
  Expect.identical(B.returnValue, b += 2); // No error - types compatible
  Expect.identical(B.returnValue, b);
  Expect.identical(2, B.argument);

  b = origB;
  B.returnValue = new A();
  B.argument = null;
  Expect.throwsTypeError(() {
    b += 3;
  });
  // The exception should have happened after the call to operator+ but before
  // the assignment to b.
  Expect.identical(origB, b);
  Expect.identical(3, B.argument);

  b = origB;
  B.returnValue = new B();
  B.argument = null;
  Expect.identical(B.returnValue, ++b); // No error - types compatible
  Expect.identical(B.returnValue, b);
  Expect.identical(1, B.argument);

  b = origB;
  B.returnValue = new A();
  B.argument = null;
  Expect.throwsTypeError(() {
    ++b;
  });
  // The exception should have happened after the call to operator+ but before
  // the assignment to b.
  Expect.identical(origB, b);
  Expect.identical(1, B.argument);

  b = origB;
  B.returnValue = new B();
  B.argument = null;
  Expect.identical(origB, b++); // No error - types compatible
  Expect.identical(B.returnValue, b);
  Expect.identical(1, B.argument);

  b = origB;
  B.returnValue = new A();
  B.argument = null;
  Expect.throwsTypeError(() {
    b++;
  });
  // The exception should have happened after the call to operator+ but before
  // the assignment to b.
  Expect.identical(origB, b);
  Expect.identical(1, B.argument);
}
