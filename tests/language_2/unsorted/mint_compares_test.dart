// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10

import "package:expect/expect.dart";

// Test compares on 64-bit integers.

compareTest() {
  Expect.isFalse(4294967296 < 6);
  Expect.isFalse(4294967296 < 4294967296);
  Expect.isFalse(4294967296 <= 6);
  Expect.isTrue(4294967296 <= 4294967296);
  Expect.isFalse(4294967296 < 4294967295);

  Expect.isTrue(-4294967296 < 6);
  Expect.isTrue(-4294967296 < 4294967296);
  Expect.isTrue(-4294967296 <= 6);
  Expect.isTrue(-4294967296 <= 4294967296);
  Expect.isTrue(-4294967296 < 4294967295);

  Expect.isFalse(4294967296 < -6);
  Expect.isFalse(4294967296 <= -6);
  Expect.isFalse(4294967296 < -4294967295);

  Expect.isTrue(-4294967296 < -6);
  Expect.isTrue(-4294967296 <= -6);
  Expect.isTrue(-4294967296 < -4294967295);

  Expect.isTrue(4294967296 > 6);
  Expect.isFalse(4294967296 > 4294967296);
  Expect.isTrue(4294967296 >= 6);
  Expect.isTrue(4294967296 >= 4294967296);
  Expect.isTrue(4294967296 > 4294967295);

  Expect.isFalse(-4294967296 > 6);
  Expect.isFalse(-4294967296 > 4294967296);
  Expect.isFalse(-4294967296 >= 6);
  Expect.isFalse(-4294967296 >= 4294967296);
  Expect.isFalse(-4294967296 > 4294967295);

  Expect.isTrue(4294967296 > -6);
  Expect.isTrue(4294967296 >= -6);
  Expect.isTrue(4294967296 > -4294967295);

  Expect.isFalse(-4294967296 > -6);
  Expect.isFalse(-4294967296 >= -6);
  Expect.isFalse(-4294967296 > -4294967295);

  Expect.isTrue(4294967296 < 9223372036854775807);
  Expect.isTrue(-4294967296 < 9223372036854775807);
  Expect.isFalse(4294967296 < -9223372036854775808);
  Expect.isFalse(-4294967296 < -9223372036854775808);
}

compareTest2(lt, lte, gt, gte) {
  Expect.isFalse(lt(4294967296, 6));
  Expect.isFalse(lte(4294967296, 6));
  Expect.isTrue(gt(4294967296, 6));
  Expect.isTrue(gte(4294967296, 6));

  Expect.isTrue(lte(-1, -1));
  Expect.isTrue(gte(-1, -1));
  Expect.isTrue(lte(-2, -1));
  Expect.isFalse(gte(-2, -1));
  Expect.isTrue(lte(-4294967296, -1));
  Expect.isFalse(gte(-4294967296, -1));

  Expect.isTrue(lt(-2, -1));
  Expect.isFalse(gt(-2, -1));
  Expect.isTrue(lt(-4294967296, -1));
  Expect.isFalse(gt(-4294967296, -1));

  Expect.isFalse(lt(-1, -4294967296));
  Expect.isTrue(gt(-1, -4294967296));
  Expect.isFalse(lt(2, -2));
  Expect.isTrue(gt(2, -2));
  Expect.isFalse(lt(4294967296, -1));
  Expect.isTrue(gt(4294967296, -1));
}

compareTestWithZero(lt, lte, gt, gte, eq, ne) {
  Expect.isFalse(lt(4294967296));
  Expect.isFalse(lte(4294967296));
  Expect.isTrue(gt(4294967296));
  Expect.isTrue(gte(4294967296));
  Expect.isFalse(eq(4294967296));
  Expect.isTrue(ne(4294967296));

  Expect.isTrue(lt(-1));
  Expect.isTrue(lte(-1));
  Expect.isFalse(gt(-1));
  Expect.isFalse(gte(-1));
  Expect.isFalse(eq(-1));
  Expect.isTrue(ne(-1));

  Expect.isTrue(lt(-2));
  Expect.isTrue(lte(-2));
  Expect.isFalse(gt(-2));
  Expect.isFalse(gte(-2));
  Expect.isFalse(eq(-2));
  Expect.isTrue(ne(-2));

  Expect.isTrue(lt(-4294967296));
  Expect.isTrue(lte(-4294967296));
  Expect.isFalse(gt(-4294967296));
  Expect.isFalse(gte(-4294967296));
  Expect.isFalse(eq(-4294967296));
  Expect.isTrue(ne(-4294967296));

  Expect.isFalse(lt(0));
  Expect.isTrue(lte(0));
  Expect.isFalse(gt(0));
  Expect.isTrue(gte(0));
  Expect.isTrue(eq(0));
  Expect.isFalse(ne(0));
}

bool lt1(a, b) => a < b;
bool lte1(a, b) => a <= b;
bool gt1(a, b) => a > b;
bool gte1(a, b) => a >= b;

bool lt2(a, b) => a < b ? true : false;
bool lte2(a, b) => a <= b ? true : false;
bool gt2(a, b) => a > b ? true : false;
bool gte2(a, b) => a >= b ? true : false;

bool int_lt1(int a) => a < 0;
bool int_lte1(int a) => a <= 0;
bool int_gt1(int a) => a > 0;
bool int_gte1(int a) => a >= 0;
bool int_eq1(int a) => a == 0;
bool int_ne1(int a) => a != 0;

bool int_lt2(int a) => a < 0 ? true : false;
bool int_lte2(int a) => a <= 0 ? true : false;
bool int_gt2(int a) => a > 0 ? true : false;
bool int_gte2(int a) => a >= 0 ? true : false;
bool int_eq2(int a) => a == 0 ? true : false;
bool int_ne2(int a) => a != 0 ? true : false;

main() {
  for (var i = 0; i < 20; i++) {
    compareTest();
    compareTest2(lt1, lte1, gt1, gte1);
    compareTest2(lt2, lte2, gt2, gte2);

    compareTestWithZero(int_lt1, int_lte1, int_gt1, int_gte1, int_eq1, int_ne1);
    compareTestWithZero(int_lt2, int_lte2, int_gt2, int_gte2, int_eq2, int_ne2);
  }
}
