// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test inlining of assignments in parameter passing. If [StringScanner.charAt]
// is inlined, the argument expresion [: ++byteOffset :] should not be
// duplicated.

class StringScanner {
  final String string;
  int byteOffset = -1;

  StringScanner(this.string);

  int nextByte() => charAt(++byteOffset);

  int charAt(index) => (string.length > index) ? string.codeUnitAt(index) : -1;
}

void main() {
  var scanner = new StringScanner('az9');
  Expect.equals(0x61, scanner.nextByte()); // Expect a.
  Expect.equals(0x7A, scanner.nextByte()); // Expect z.
  Expect.equals(0x39, scanner.nextByte()); // Expect 9.
  Expect.equals(-1, scanner.nextByte());
}
