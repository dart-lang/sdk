// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/flutter/flutter/issues/98967.
// Verifies that compiler doesn't generate wrong code for comparison of ints
// due to a late change in the representation of EqualityCompare inputs.

import 'package:expect/expect.dart';

class C {
  int? val;

  @pragma('vm:never-inline')
  void testImpl(bool Function(int) compare) {
    for (var i = 0; i < 2; i++) {
      Expect.equals(false, compare(i));
      val = i;
      Expect.equals(true, compare(i));
    }

    final mint0 = int.parse("7fffffffffffffff", radix: 16);
    final mint1 = int.parse("7fffffffffffffff", radix: 16);
    if (mint0 != mint1) throw 'This is the same mint value';

    Expect.equals(false, compare(mint0));
    val = mint0;
    Expect.equals(true, compare(mint0));
    Expect.equals(true, compare(mint1),
        'expected two different mints with the same value compare equal');
  }

  @pragma('vm:never-inline')
  static void blackhole(void Function() f) {
    f();
  }

  void test() {
    return testImpl((v) {
      // Note: need multiple context levels in the chain to delay
      // optimizer forwarding load of [val] and subsequently
      // clearing null_aware flag on the equality comparison.
      // Hence the closure capturing [v] below.
      final result = val != null ? val == v : false;
      blackhole(() => v);
      return result;
    });
  }
}

void main() {
  C().test();
}
