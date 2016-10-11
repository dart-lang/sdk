// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

oneOptionalArgument(a, {b}) {
  Expect.equals(1, a);
  Expect.equals(2, b);
}

twoOptionalArguments({a, b}) {
  Expect.equals(1, a);
  Expect.equals(2, b);
}

main() {
  twoOptionalArguments(a: 1, b: 2);
  twoOptionalArguments(b: 2, a: 1);

  oneOptionalArgument(1, b: 2);

  new A.twoOptionalArguments(a: 1, b: 2);
  new A.twoOptionalArguments(b: 2, a: 1);

  new A.oneOptionalArgument(1, b: 2);

  new B.one();
  new B.two();
  new B.three();

  new B().B_one();
  new B().B_two();
  new B().B_three();
}

class A {
  A.oneOptionalArgument(a, {b}) {
    Expect.equals(1, a);
    Expect.equals(2, b);
  }

  A.twoOptionalArguments({a, b}) {
    Expect.equals(1, a);
    Expect.equals(2, b);
  }

  A();

  // A named constructor now conflicts with a method of the same name.
  oneOptArg(a, {b}) {
    Expect.equals(1, a);
    Expect.equals(2, b);
  }

  twoOptArgs({a, b}) {
    Expect.equals(1, a);
    Expect.equals(2, b);
  }
}

class B extends A {
  B.one() : super.twoOptionalArguments(a: 1, b: 2);
  B.two() : super.twoOptionalArguments(b: 2, a: 1);
  B.three() : super.oneOptionalArgument(1, b: 2);

  B();
  B_one() {
    super.twoOptArgs(a: 1, b: 2);
  }

  B_two() {
    super.twoOptArgs(b: 2, a: 1);
  }

  B_three() {
    super.oneOptArg(1, b: 2);
  }
}
