// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void main() {
  // Normal modifiable list.
  var l1 = [0, 1, 2, 3, 4];

  bool checkedMode = false;
  assert(checkedMode = true);

  // Index must be integer and in range.
  Expect.throws(() { l1.removeAt(-1); },
                (e) => e is IndexOutOfRangeException,
                "negative");
  Expect.throws(() { l1.removeAt(5); },
                (e) => e is IndexOutOfRangeException,
                "too large");
  Expect.throws(() { l1.removeAt(null); },
                (e) => e is ArgumentError,
                "too large");
  Expect.throws(() { l1.removeAt("1"); },
                (e) => (checkedMode ? e is TypeError
                                    : e is ArgumentError),
                "string");
  Expect.throws(() { l1.removeAt(1.5); },
                (e) => (checkedMode ? e is TypeError
                                    : e is ArgumentError),
                "double");

  Expect.equals(2, l1.removeAt(2), "l1-remove2");
  Expect.equals(1, l1[1], "l1-1[1]");

  Expect.equals(3, l1[2], "l1-1[2]");
  Expect.equals(4, l1[3], "l1-1[3]");
  Expect.equals(4, l1.length, "length-1");

  Expect.equals(0, l1.removeAt(0), "l1-remove0");
  Expect.equals(1, l1[0], "l1-2[0]");
  Expect.equals(3, l1[1], "l1-2[1]");
  Expect.equals(4, l1[2], "l1-2[2]");
  Expect.equals(3, l1.length, "length-2");

  // Fixed size list.
  var l2 = new List(5);
  for (var i = 0; i < 5; i++) l2[i] = i;
  Expect.throws(() { l2.removeAt(2); },
                (e) => e is UnsupportedError,
                "fixed-length");

  // Unmodifiable list.
  var l3 = const [0, 1, 2, 3, 4];
  Expect.throws(() { l3.removeAt(2); },
                (e) => e is UnsupportedError,
                "unmodifiable");

  // Empty list is not special.
  var l4 = [];
  Expect.throws(() { l4.removeAt(0); },
                (e) => e is IndexOutOfRangeException,
                "empty");
}
