// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  testLowerUpper();
  testSpecialCases();
}

void testLowerUpper() {
  var a = "Stop! Smell the Roses.";
  var allLower = "stop! smell the roses.";
  var allUpper = "STOP! SMELL THE ROSES.";
  Expect.equals(allUpper, a.toUpperCase());
  Expect.equals(allLower, a.toLowerCase());
}

void testSpecialCases() {
  // Letters in Latin-1 where the upper case is not in Latin-1.

  // German sharp s. Upper case variant is "SS".
  Expect.equals("SS", "\xdf".toUpperCase()); //                 //# 01: ok
  Expect.equals("\xdf", "\xdf".toLowerCase());
  Expect.equals("ss", "\xdf".toUpperCase().toLowerCase()); //   //# 01: continued
  // Micro sign (not same as lower-case Greek letter mu, U+03BC).
  Expect.equals("\u039c", "\xb5".toUpperCase()); //             //# 02: ok
  Expect.equals("\xb5", "\xb5".toLowerCase());
  Expect.equals("\u03Bc", //                                    //# 02: continued
                "\xb5".toUpperCase().toLowerCase()); //         //# 02: continued
  // Small letter y diaresis.
  Expect.equals("\u0178", "\xff".toUpperCase()); //             //# 03: ok
  Expect.equals("\xff", "\xff".toLowerCase());
  Expect.equals("\xff", "\xff".toUpperCase().toLowerCase()); // //# 03: continued
  // Zero.
  Expect.equals("\x00", "\x00".toLowerCase());
  Expect.equals("\x00", "\x00".toUpperCase());

  // Test all combinations of ordering of lower-case, upper-case and
  // special-when-upper-cased characters.
  Expect.equals("AA\u0178", "Aa\xff".toUpperCase()); //         //# 03: continued
  Expect.equals("AA\u0178", "aA\xff".toUpperCase()); //         //# 03: continued
  Expect.equals("A\u0178A", "A\xffa".toUpperCase()); //         //# 03: continued
  Expect.equals("A\u0178A", "a\xffA".toUpperCase()); //         //# 03: continued
  Expect.equals("\u0178AA", "\xffAa".toUpperCase()); //         //# 03: continued
  Expect.equals("\u0178AA", "\xffaA".toUpperCase()); //         //# 03: continued

  Expect.equals("aa\xff", "Aa\xff".toLowerCase());
  Expect.equals("aa\xff", "aA\xff".toLowerCase());
  Expect.equals("a\xffa", "A\xffa".toLowerCase());
  Expect.equals("a\xffa", "a\xffA".toLowerCase());
  Expect.equals("\xffaa", "\xffAa".toLowerCase());
  Expect.equals("\xffaa", "\xffaA".toLowerCase());
}
