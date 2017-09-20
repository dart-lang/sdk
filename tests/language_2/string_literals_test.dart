// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  var expect = new String.fromCharCodes(
      [0, 0x0a, 0x0d, 0x7f, 0xff, 0xffff, 0xd800, 0xdc00, 0xdbff, 0xdfff]);
  test(string) {
    Expect.equals(expect, string);
  }

  // Plain escapes of code points.
  test("\x00\x0a\x0d\x7f\xff\uffff\u{10000}\u{10ffff}");
  test("""\x00\x0a\x0d\x7f\xff\uffff\u{10000}\u{10ffff}""");
  test('\x00\x0a\x0d\x7f\xff\uffff\u{10000}\u{10ffff}');
  test('''\x00\x0a\x0d\x7f\xff\uffff\u{10000}\u{10ffff}''');
  // Plain escapes of individual code units.
  test("\x00\x0a\x0d\x7f\xff\uffff\ud800\udc00\udbff\udfff");
  test("""\x00\x0a\x0d\x7f\xff\uffff\ud800\udc00\udbff\udfff""");
  test('\x00\x0a\x0d\x7f\xff\uffff\ud800\udc00\udbff\udfff');
  test('''\x00\x0a\x0d\x7f\xff\uffff\ud800\udc00\udbff\udfff''');
  // Insert newline into multiline string.
  test("""\x00
\x0d\x7f\xff\uffff\ud800\udc00\udbff\udfff""");
  test('''\x00
\x0d\x7f\xff\uffff\ud800\udc00\udbff\udfff''');
  // Extract code points from multi-character escape string.
  test("\x00\x0a\x0d\x7f\xff\uffff"
      "${"\u{10000}"[0]}${"\u{10000}"[1]}"
      "${"\u{10FFFF}"[0]}${"\u{10FFFF}"[1]}");
  test("\x00\x0a\x0d\x7f\xff\uffff" + "\ud800" + "\udc00\udbff" + "\udfff");
  // Single line string over multiple lines with newlines inside interpolation.
  test("\x00\x0a\x0d\x7f\xff${
           ""
       }\uffff\ud800\udc00\udbff\udfff");
}
