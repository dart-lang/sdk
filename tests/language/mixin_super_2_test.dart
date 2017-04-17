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

class D extends R with B {
  toString() => 'D<' + super.toString() + '>';
}

class E extends D with B {
  toString() => 'E{' + super.toString() + '}';
}

class F = R with B, B;

class G extends F with B {
  toString() => 'G{' + super.toString() + '}';
}

main() {
  check(object, String expected) {
    Expect.equals(expected, object.toString());
  }

  check(new B(), "B(Instance of 'B')");
  check(new R(), "R[Instance of 'R']");
  check(new D(), "D<B(R[Instance of 'D'])>");
  check(new E(), "E{B(D<B(R[Instance of 'E'])>)}");
  check(new F(), "B(B(R[Instance of 'F']))");
  check(new G(), "G{B(B(B(R[Instance of 'G'])))}");
}
