// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  bool checkedMode = false;
  assert(checkedMode = true);

  for (int i = 0; i < 36 * 36 + 1; i++) {
    for (int r = 2; r <= 36; r++) {
      String radixString = i.toRadixString(r);
      Expect.equals(i, int.parse(radixString, radix: r), "");
      Expect.equals(i, int.parse(" $radixString", radix: r), "");
      Expect.equals(i, int.parse("$radixString ", radix: r), "");
      Expect.equals(i, int.parse(" $radixString ", radix: r), "");
      Expect.equals(i, int.parse("+$radixString", radix: r), "");
      Expect.equals(i, int.parse(" +$radixString", radix: r), "");
      Expect.equals(i, int.parse("+$radixString ", radix: r), "");
      Expect.equals(i, int.parse(" +$radixString ", radix: r), "");
      Expect.equals(-i, int.parse("-$radixString", radix: r), "");
      Expect.equals(-i, int.parse(" -$radixString", radix: r), "");
      Expect.equals(-i, int.parse("-$radixString ", radix: r), "");
      Expect.equals(-i, int.parse(" -$radixString ", radix: r), "");
    }
  }
  // Allow both upper- and lower-case letters.
  Expect.equals(0xABCD, int.parse("ABCD", radix: 16));
  Expect.equals(0xABCD, int.parse("abcd", radix: 16)); 
  Expect.equals(15628859, int.parse("09azAZ", radix: 36));

  // Allow whitespace before and after the number.
  Expect.equals(1, int.parse(" 1", radix: 2));
  Expect.equals(1, int.parse("1 ", radix: 2));
  Expect.equals(1, int.parse(" 1 ", radix: 2));
  Expect.equals(1, int.parse("\n1", radix: 2));
  Expect.equals(1, int.parse("1\n", radix: 2));
  Expect.equals(1, int.parse("\n1\n", radix: 2));
  Expect.equals(1, int.parse("+1", radix: 2));

  void testFails(String source, int radix) {
    Expect.throws(() { throw int.parse(source, radix: radix,
                                       onError: (s) { throw "FAIL"; }); },
                  (e) => e == "FAIL",
                  "$source/$radix");
    Expect.equals(-999, int.parse(source, radix: radix, onError: (s) => -999));
  }
  for (int i = 2; i < 36; i++) {
    testFails(i.toRadixString(36), i);
  }
  testFails("", 2);
  testFails("0x10", 16);  // No 0x specially allowed.
  testFails("+ 1", 2);  // No space between sign and digits.
  testFails("- 1", 2);  // No space between sign and digits.

  testBadTypes(var source, var radix) {
    if (!checkedMode) {
      // No promises on what error is thrown if the type doesn't match.
      // Likely either ArgumentError or NoSuchMethodError.
      Expect.throws(() => int.parse(source, radix: radix, onError: (s) => 0));
      return;
    }
    // In checked mode, it's always a TypeError.
    Expect.throws(() => int.parse(source, radix: radix, onError: (s) => 0),
                  (e) => e is TypeError);
  }

  testBadTypes(9, 10);
  testBadTypes(true, 10);
  testBadTypes("0", true);
  testBadTypes("0", "10");

  testBadArguments(String source, int radix) {
    // If the types match, it should be an ArgumentError of some sort.
    Expect.throws(() => int.parse(source, radix: radix, onError: (s) => 0),
                  (e) => e is ArgumentError);
  }

  testBadArguments("0", -1);
  testBadArguments("0", 0);
  testBadArguments("0", 1);
  testBadArguments("0", 37);

  // If handleError isn't an unary function, and it's called, it also throws
  // (either TypeError in checked mode, or some failure in unchecked mode).
  Expect.throws(() => int.parse("9", radix: 8, onError: "not a function"));
  Expect.throws(() => int.parse("9", radix: 8, onError: () => 42));
  Expect.throws(() => int.parse("9", radix: 8, onError: (v1, v2) => 42));
}
