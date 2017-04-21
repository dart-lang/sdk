// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Characters with Whitespace property (Unicode 6.3).
// 0009..000D    ; White_Space # Cc       <control-0009>..<control-000D>
// 0020          ; White_Space # Zs       SPACE
// 0085          ; White_Space # Cc       <control-0085>
// 00A0          ; White_Space # Zs       NO-BREAK SPACE
// 1680          ; White_Space # Zs       OGHAM SPACE MARK
// 2000..200A    ; White_Space # Zs       EN QUAD..HAIR SPACE
// 2028          ; White_Space # Zl       LINE SEPARATOR
// 2029          ; White_Space # Zp       PARAGRAPH SEPARATOR
// 202F          ; White_Space # Zs       NARROW NO-BREAK SPACE
// 205F          ; White_Space # Zs       MEDIUM MATHEMATICAL SPACE
// 3000          ; White_Space # Zs       IDEOGRAPHIC SPACE
// And BOM:
// FEFF          ; Byte order mark.
const WHITESPACE = const [
  0x09,
  0x0A,
  0x0B,
  0x0C,
  0x0D,
  0x20,
  0x85,
  0xA0,
  0x1680,
  0x2000,
  0x2001,
  0x2002,
  0x2003,
  0x2004,
  0x2005,
  0x2006,
  0x2007,
  0x2008,
  0x2009,
  0x200A,
  0x2028,
  0x2029,
  0x202F,
  0x205F,
  0x3000,
  0xFEFF,
];

main() {
  // Test the whitespace in different positions.
  test(ws) {
    // trimLeft
    Expect.equals("", ws.trimLeft(), "K1");
    Expect.equals("", (ws + ws).trimLeft(), "L2");
    Expect.equals("a" + ws, ("a" + ws).trimLeft(), "L3");
    Expect.equals("a", (ws + "a").trimLeft(), "L4");
    Expect.equals("a" + ws + ws, (ws + ws + "a" + ws + ws).trimLeft(), "L5");
    Expect.equals("a" + ws + "a", (ws + ws + "a" + ws + "a").trimLeft(), "L6");
    var untrimmable = "a" + ws + "a";
    Expect.identical(untrimmable, untrimmable.trimLeft(), "L7");
    // trimRight
    Expect.equals("", ws.trimRight(), "R1");
    Expect.equals("", (ws + ws).trimRight(), "R2");
    Expect.equals("a", ("a" + ws).trimRight(), "R3");
    Expect.equals(ws + "a", (ws + "a").trimRight(), "R4");
    Expect.equals(ws + ws + "a", (ws + ws + "a" + ws + ws).trimRight(), "R5");
    Expect.equals("a" + ws + "a", ("a" + ws + "a" + ws + ws).trimRight(), "R6");
    Expect.identical(untrimmable, untrimmable.trimRight(), "R7");
  }

  // Test each whitespace at different locations.
  for (var ws in WHITESPACE) {
    var c = new String.fromCharCode(ws);
    test(c);
  }
  // Test all whitespaces at once at different locations.
  test(new String.fromCharCodes(WHITESPACE));

  // Empty strings.
  Expect.identical("", "".trimLeft());
  Expect.identical("", "".trimRight());

  // Test all BMP chars and one surrogate pair.
  for (int i = 0, j = 0; i <= 0x10000; i++) {
    if (j < WHITESPACE.length && i == WHITESPACE[j]) {
      j++;
      continue;
    }
    // See below for these exceptions.
    if (i == 0x180E) continue;
    if (i == 0x200B) continue;

    var s = new String.fromCharCode(i);
    Expect.identical(s, s.trimLeft());
    Expect.identical(s, s.trimRight());
  }

  // U+200b is currently being treated as whitespace by some JS engines.
  // string_trimlr_test/01 fails on these engines.
  // Should be fixed in tip-of-tree V8 per 2014-02-10.
  var s200B = new String.fromCharCode(0x200B);
  Expect.identical(s200B, s200B.trimLeft()); //    //# 01: ok
  Expect.identical(s200B, s200B.trimRight()); //   //# 01: ok

  // U+180E ceased to be whitespace in Unicode version 6.3.0
  // string_trimlr_test/02 fails on implementations using earlier versions.
  var s180E = new String.fromCharCode(0x180E);
  Expect.identical(s180E, s180E.trimLeft()); //    //# 02: ok
  Expect.identical(s180E, s180E.trimRight()); //   //# 02: ok
}
