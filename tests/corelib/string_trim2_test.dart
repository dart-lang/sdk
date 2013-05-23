// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// TODO(floitsch): Test 0x85 when dart2js supports it.
const WHITESPACE = const [
  0x09,
  0x0A,
  0x0B,
  0x0C,
  0x0D,
  0x20,
  0xA0,
  0x1680,
  0x180E,
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
  0x202F,
  0x205F,
  0x3000,
  0x2028,
  0x2029,
  0xFEFF,
];

main() {
  for (var ws in WHITESPACE) {
    Expect.equals("", new String.fromCharCode(ws).trim());
  }
  Expect.equals("", new String.fromCharCodes(WHITESPACE).trim());
  for (var ws in WHITESPACE) {
    var c = new String.fromCharCode(ws);
    Expect.equals("a", ("a" + c).trim());
    Expect.equals("a", (c + "a").trim());
    Expect.equals("a", (c + c + "a" + c + c).trim());
    Expect.equals("a" + c + "a", (c + c + "a" + c + "a" + c + c).trim());
  }
}
