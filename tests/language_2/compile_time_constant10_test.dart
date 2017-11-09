// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test that 'identical(a,b)' is a compile-time constant.

class C {
  final x;
  const C(this.x);
  static f3() {}
  static f4() {}
}

const i1 = 1;
const i2 = 2;
const d1 = 1.5;
const d2 = 2.5;
const b1 = true;
const b2 = false;
const s1 = "1";
const s2 = "2";
const l1 = const [1, 2];
const l2 = const [2, 3];
const m1 = const {"x": 1};
const m2 = const {"x": 2};
const c1 = const C(1);
const c2 = const C(2);
f1() {}
f2() {}
const id = identical;

class CT {
  final x1;
  final x2;
  final bool id;
  const CT(var x1, var x2)
      : this.x1 = x1,
        this.x2 = x2,
        this.id = identical(x1, x2);
  void test(void expect(a, String b), name) {
    expect(id, "$name: identical($x1,$x2)");
  }
}

const trueTests = const [
  const CT(2 - 1, i1),
  const CT(1 + 1, i2),
  const CT(2.5 - 1.0, d1),
  const CT(1.5 + 1.0, d2),
  const CT(false || true, b1),
  const CT(true && false, b2),
  const CT('$i1', s1),
  const CT('$i2', s2),
  const CT(const [i1, 2], l1),
  const CT(const [i2, 3], l2),
  const CT(const {"x": i1}, m1),
  const CT(const {"x": i2}, m2),
  const CT(const C(i1), c1),
  const CT(const C(i2), c2),
  const CT(f1, f1),
  const CT(f2, f2),
  const CT(C.f3, C.f3),
  const CT(C.f4, C.f4),
  const CT(id, identical),
];

const falseTests = const [
  const CT(i1, i2),
  const CT(d1, d2),
  const CT(b1, b2),
  const CT(s1, s2),
  const CT(l1, l2),
  const CT(m1, m2),
  const CT(c1, c2),
  const CT(f1, f2),
  const CT(i1, d1),
  const CT(d1, b1),
  const CT(b1, s1),
  const CT(s1, l1),
  const CT(l1, m1),
  const CT(m1, c1),
  const CT(c1, f1),
  const CT(f1, C.f3),
  const CT(C.f3, identical),
  const CT(identical, i1),
];

// Not a constant if it's not written 'identical'.
const idtest = id(i1, i2); // //# 01: compile-time error

// Not a constant if aliased? (Current interpretation, waiting for
// confirmation).
class T { //                                    //# 02: compile-time error
  static const identical = id; //               //# 02: continued
  static const idtest2 = identical(i1, i2); //  //# 02: continued
} //                                            //# 02: continued

main() {
  for (int i = 0; i < trueTests.length; i++) {
    trueTests[i].test(Expect.isTrue, "true[$i]");
  }
  for (int i = 0; i < falseTests.length; i++) {
    falseTests[i].test(Expect.isFalse, "false[$i]");
  }

  var x = idtest; // //# 01: continued
  var x = T.idtest2; // //# 02: continued
}
