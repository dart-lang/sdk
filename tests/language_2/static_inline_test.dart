// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test inlining of assignments in parameter passing. If [StringScanner.charAt]
// is inlined, the argument expression [: ++byteOffset :] should not be
// duplicated.

class StringScanner {
  static String string;
  int byteOffset = -1;

  int nextByte(foo) {
    if (foo) return -2;
    return charAt(++byteOffset);
  }

  static int charAt(index) =>
      (string.length > index) ? string.codeUnitAt(index) : -1;
}

void main() {
  var scanner = new StringScanner();
  StringScanner.string = 'az9';
  Expect.equals(0x61, scanner.nextByte(false)); // Expect a.
  Expect.equals(0x7A, scanner.nextByte(false)); // Expect z.
  Expect.equals(0x39, scanner.nextByte(false)); // Expect 9.
  Expect.equals(-1, scanner.nextByte(false));
}
