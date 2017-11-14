// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:convert';

import "package:expect/expect.dart";

// This only works reliabily for "ASCII" cross platform as that is the only
// well known part of the default Windows code page.
void testEncodeDecode(String str) {
  Expect.equals(SYSTEM_ENCODING.decode(SYSTEM_ENCODING.encode(str)), str);
}

// This only works reliabily for "ASCII" cross platform as that is the only
// common set of bytes between UTF-8 Windows code pages that convert back
// and forth.
void testDecodeEncode(List<int> bytes) {
  Expect.listEquals(
      SYSTEM_ENCODING.encode(SYSTEM_ENCODING.decode(bytes)), bytes);
}

void test(List<int> bytes) {
  var str = new String.fromCharCodes(bytes);
  Expect.equals(SYSTEM_ENCODING.decode(bytes), str);
  Expect.listEquals(SYSTEM_ENCODING.encode(str), bytes);
  testDecodeEncode(bytes);
  testEncodeDecode(str);
}

main() {
  test([65, 66, 67]);
  test([65, 0, 67]);
  test([0, 65, 0, 67, 0]);
  test([0, 0, 0]);
  test(new Iterable.generate(128, (i) => i).toList());
  if (Platform.isWindows) {
    // On Windows the default Windows code page cannot encode these
    // Unicode characters and the ? character is used.
    Expect.listEquals(
        SYSTEM_ENCODING.encode('\u1234\u5678\u9abc'), '???'.codeUnits);
  } else {
    // On all systems except for Windows UTF-8 is used as the system
    // encoding.
    Expect.listEquals(SYSTEM_ENCODING.encode('\u1234\u5678\u9abc'),
        utf8.encode('\u1234\u5678\u9abc'));
  }
}
