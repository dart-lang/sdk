// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

var escapeChars = r"([)}{]?*+.$^|\";

var nonEscapeAscii = "\x00\x01\x02\x03\x04\x05\x06\x07" //
    "\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f" //
    "\x10\x11\x12\x13\x14\x15\x16\x17" //
    "\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f" //
    """ !"#%&',-/0123456789:;<=>""" //
    """@ABCDEFGHIJKLMNOPQRSTUVWXYZ_""" //
    """`abcdefghijklmnopqrstuvwxyz~\x7f""";
var someNonAscii =
    new String.fromCharCodes(new List.generate(0x1000 - 128, (x) => x + 128));

test(String string, [bool shouldEscape]) {
  var escape = RegExp.escape(string);
  Expect.isTrue(new RegExp(escape).hasMatch(string), "$escape");
  Expect.equals(string, new RegExp(escape).firstMatch(string)[0], "$escape");
  if (shouldEscape == true) {
    Expect.notEquals(string, escape);
  } else if (shouldEscape == false) {
    Expect.equals(string, escape);
  }
}

main() {
  for (var c in escapeChars.split("")) {
    test(c, true);
  }
  for (var c in nonEscapeAscii.split("")) {
    test(c, false);
  }
  test(escapeChars, true);
  test(nonEscapeAscii, false);
  test(someNonAscii, false);
  test((nonEscapeAscii + escapeChars) * 3, true);
  test(r'.abc', true); // First only.
  test(r'abc.', true); // Last only.
}
