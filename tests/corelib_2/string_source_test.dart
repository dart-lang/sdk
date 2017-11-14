// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that different representations of the same string are all equal.

import "dart:convert";

import "package:expect/expect.dart";

main() {
  var base = "\u{10412}";
  var strings = [
    "\u{10412}",
    "𐐒",
    new String.fromCharCodes([0xd801, 0xdc12]),
    base[0] + base[1],
    "$base",
    "${base[0]}${base[1]}",
    "${base[0]}${base.substring(1)}",
    new String.fromCharCodes([0x10412]),
    ("a" + base).substring(1),
    (new StringBuffer()..writeCharCode(0xd801)..writeCharCode(0xdc12))
        .toString(),
    (new StringBuffer()..writeCharCode(0x10412)).toString(),
    json.decode('"\u{10412}"'),
    (json.decode('{"\u{10412}":[]}') as Map).keys.first
  ];
  for (String string in strings) {
    Expect.equals(base.length, string.length);
    Expect.equals(base, string);
    Expect.equals(base.hashCode, string.hashCode);
    Expect.listEquals(base.codeUnits.toList(), string.codeUnits.toList());
  }
}
