// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that ?? is compile-time constant.

import "package:expect/expect.dart";

const theNull = null;
const notNull = const Object();

// Top-level const field initializer.
const test1 = theNull ?? notNull;
const test2 = notNull ?? theNull;
const test3 = theNull ?? theNull ?? notNull;
const test4 = theNull ?? theNull ?? theNull;

class P {
  final v;
  const P(this.v);
}

// Annotation parameter (not checked by test!)
@P(theNull ?? notNull)
@P(notNull ?? theNull)
@P(theNull ?? theNull ?? notNull)
@P(theNull ?? theNull ?? theNull)
class C {
  // Static const field initializer.
  static const test5 = theNull ?? notNull;
  static const test6 = notNull ?? theNull;
  static const test7 = theNull ?? theNull ?? notNull;
  static const test8 = theNull ?? theNull ?? theNull;

  // (Constructor) parameter defaults.
  final test9;
  final test10;
  final test11;
  final test12;

  // Const constructor initializer list.
  final test13;
  final test14;
  final test15;
  final test16;
  final test17;

  const C(x,
      [this.test9 = theNull ?? notNull,
      this.test10 = notNull ?? theNull,
      this.test11 = theNull ?? theNull ?? notNull,
      this.test12 = theNull ?? theNull ?? theNull])
      : test13 = theNull ?? x,
        test14 = notNull ?? x,
        test15 = x ?? notNull,
        test16 = theNull ?? theNull ?? x,
        test17 = theNull ?? x ?? notNull;

  List methodLocal() {
    // Method local const variable initializer.
    const test18 = theNull ?? notNull;
    const test19 = notNull ?? theNull;
    const test20 = theNull ?? theNull ?? notNull;
    const test21 = theNull ?? theNull ?? theNull;

    return const [test18, test19, test20, test21];
  }

  List expressionLocal() {
    // Constant expression sub-expression.
    return const [
      theNull ?? notNull,
      notNull ?? theNull,
      theNull ?? theNull ?? notNull,
      theNull ?? theNull ?? theNull
    ];
  }
}

main() {
  Expect.identical(notNull, test1, "test1");
  Expect.identical(notNull, test2, "test2");
  Expect.identical(notNull, test3, "test3");
  Expect.identical(theNull, test4, "test4");

  Expect.identical(notNull, C.test5, "test5");
  Expect.identical(notNull, C.test6, "test6");
  Expect.identical(notNull, C.test7, "test7");
  Expect.identical(theNull, C.test8, "test8");

  const c1 = const C(null);
  Expect.identical(notNull, c1.test9, "test9");
  Expect.identical(notNull, c1.test10, "test10");
  Expect.identical(notNull, c1.test11, "test11");
  Expect.identical(theNull, c1.test12, "test12");

  Expect.identical(theNull, c1.test13, "test13");
  Expect.identical(notNull, c1.test14, "test14");
  Expect.identical(notNull, c1.test15, "test15");
  Expect.identical(theNull, c1.test16, "test16");
  Expect.identical(notNull, c1.test17, "test17");

  var list = c1.methodLocal();
  Expect.identical(notNull, list[0], "test18");
  Expect.identical(notNull, list[1], "test19");
  Expect.identical(notNull, list[2], "test20");
  Expect.identical(theNull, list[3], "test21");

  list = c1.expressionLocal();
  Expect.identical(notNull, list[0], "test22");
  Expect.identical(notNull, list[1], "test23");
  Expect.identical(notNull, list[2], "test24");
  Expect.identical(theNull, list[3], "test25");

  const c2 = const C(42);
  Expect.identical(notNull, c2.test9, "test26");
  Expect.identical(notNull, c2.test10, "test27");
  Expect.identical(notNull, c2.test11, "test28");
  Expect.identical(theNull, c2.test12, "test29");

  Expect.identical(42, c2.test13, "test30");
  Expect.identical(notNull, c2.test14, "test31");
  Expect.identical(42, c2.test15, "test32");
  Expect.identical(42, c2.test16, "test33");
  Expect.identical(42, c2.test17, "test34");

  list = c2.methodLocal();
  Expect.identical(notNull, list[0], "test35");
  Expect.identical(notNull, list[1], "test36");
  Expect.identical(notNull, list[2], "test37");
  Expect.identical(theNull, list[3], "test38");

  list = c2.expressionLocal();
  Expect.identical(notNull, list[0], "test39");
  Expect.identical(notNull, list[1], "test40");
  Expect.identical(notNull, list[2], "test41");
  Expect.identical(theNull, list[3], "test42");
}
