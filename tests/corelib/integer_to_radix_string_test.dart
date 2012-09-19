// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  // Test that we accept radix 2 to 36 and that we use lower-case
  // letters.
  var expected = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
                  'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j',
                  'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't',
                  'u', 'v', 'w', 'x', 'y', 'z'];
  for (var radix = 2; radix < 37; radix++) {
    for (var i = 0; i < radix; i++) {
      Expect.equals(expected[i], i.toRadixString(radix));
    }
  }

  var illegalRadices = [ -1, 0, 1, 37 ];
  for (var radix in illegalRadices) {
    try {
      42.toRadixString(radix);
      Expect.fail("Exception expected");
    } on IllegalArgumentException catch (e) {
      // Nothing to do.
    }
  }
}
