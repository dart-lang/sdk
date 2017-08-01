// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  Expect.equals("A", new String.fromCharCode(65));
  Expect.equals("B", new String.fromCharCode(66));
  var gClef = new String.fromCharCode(0x1D11E);
  Expect.equals(2, gClef.length);
  Expect.equals(0xD834, gClef.codeUnitAt(0));
  Expect.equals(0xDD1E, gClef.codeUnitAt(1));

  // Unmatched surrogates.
  var unmatched = new String.fromCharCode(0xD800);
  Expect.equals(1, unmatched.length);
  Expect.equals(0xD800, unmatched.codeUnitAt(0));
  unmatched = new String.fromCharCode(0xDC00);
  Expect.equals(1, unmatched.length);
  Expect.equals(0xDC00, unmatched.codeUnitAt(0));

  Expect.throws(() => new String.fromCharCode(-1), (e) => e is ArgumentError);

  // Invalid code point.
  Expect.throws(
      () => new String.fromCharCode(0x110000), (e) => e is ArgumentError);

  Expect.throws(
      () => new String.fromCharCode(0x110001), (e) => e is ArgumentError);
}
