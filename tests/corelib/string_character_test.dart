// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  Expect.equals("A", new String.character(65));
  Expect.equals("B", new String.character(66));
  var gClef = new String.character(0x1D11E);
  Expect.equals(2, gClef.length);
  Expect.equals(0xD834, gClef.charCodeAt(0));
  Expect.equals(0xDD1E, gClef.charCodeAt(1));

  // Unmatched surrogates.
  var unmatched = new String.character(0xD800);
  Expect.equals(1, unmatched.length);
  Expect.equals(0xD800, unmatched.charCodeAt(0));
  unmatched = new String.character(0xDC00);
  Expect.equals(1, unmatched.length);
  Expect.equals(0xDC00, unmatched.charCodeAt(0));

  Expect.throws(() => new String.character(-1),
                (e) => e is ArgumentError);

  // Invalid code point.
  Expect.throws(() => new String.character(0x110000),
                (e) => e is ArgumentError);

  Expect.throws(() => new String.character(0x110001),
                (e) => e is ArgumentError);
}
