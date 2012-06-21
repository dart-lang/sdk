// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

oneOptionalArgument(a, [b]) {
  Expect.equals(1, a);
  Expect.equals(2, b);
}

twoOptionalArguments([a, b]) {
  Expect.equals(1, a);
  Expect.equals(2, b);
}

main() {
  twoOptionalArguments(a: 1, b: 2);
  twoOptionalArguments(b: 2, a: 1);
  twoOptionalArguments(1, b: 2);
  twoOptionalArguments(1, 2);

  oneOptionalArgument(1, 2);
  oneOptionalArgument(1, b: 2);

  new A.twoOptionalArguments(a: 1, b: 2);
  new A.twoOptionalArguments(b: 2, a: 1);
  new A.twoOptionalArguments(1, b: 2);
  new A.twoOptionalArguments(1, 2);

  new A.oneOptionalArgument(1, 2);
  new A.oneOptionalArgument(1, b: 2);

/* TODO(ngeoffray): Enable once we support super constructor call.
  new B.one();
  new B.two();
  new B.three();
  new B.four();
  new B.five();
  new B.six();
*/

  new B().one();
  new B().two();
  new B().three();
  new B().four();
  new B().five();
  new B().six();
}

class A {
  A.oneOptionalArgument(a, [b]) {
    Expect.equals(1, a);
    Expect.equals(2, b);
  }

  A.twoOptionalArguments([a, b]) {
    Expect.equals(1, a);
    Expect.equals(2, b);
  }

  A();

  oneOptionalArgument(a, [b]) {
    Expect.equals(1, a);
    Expect.equals(2, b);
  }

  twoOptionalArguments([a, b]) {
    Expect.equals(1, a);
    Expect.equals(2, b);
  }
}

class B extends A {
  B.one() : super.twoOptionalArguments(a: 1, b: 2);
  B.two() : super.twoOptionalArguments(b: 2, a: 1);
  B.three() : super.twoOptionalArguments(1, b: 2);
  B.four() : super.twoOptionalArguments(1, 2);
  B.five() : super.oneOptionalArgument(1, 2);
  B.six() : super.oneOptionalArgument(1, b: 2);

  B();
  one() { super.twoOptionalArguments(a: 1, b: 2); }
  two() { super.twoOptionalArguments(b: 2, a: 1); }
  three() { super.twoOptionalArguments(1, b: 2); }
  four() { super.twoOptionalArguments(1, 2); }
  five() { super.oneOptionalArgument(1, 2); }
  six() { super.oneOptionalArgument(1, b: 2); }
}
