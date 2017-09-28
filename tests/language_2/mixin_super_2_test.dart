// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// SharedOptions=--supermixin

import "package:expect/expect.dart";

class B {
  // 'super' resolves to Object, and in some tests, multiple points in the
  // inheritance chain.
  toString() => 'B(' + super.toString() + ')';
}

class R {
  toString() => 'R[' + super.toString() + ']';
}

class D extends R with B { //# 01: compile-time error
  toString() => 'D<' + super.toString() + '>'; //# 01: continued
} //# 01: continued

class E extends D with B { //# 02: compile-time error
  toString() => 'E{' + super.toString() + '}'; //# 02: continued
} //# 02: continued

class F = R with B, B;  //# 03: compile-time error

class G extends F with B { //# 04: compile-time error
  toString() => 'G{' + super.toString() + '}';  //# 04: continued
}  //# 04: continued

main() {
  check(object, String expected) {
    Expect.equals(expected, object.toString());
  }

  check(new B(), "B(Instance of 'B')");
  check(new R(), "R[Instance of 'R']");
}
