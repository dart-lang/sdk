// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library utf.unicode_core_test;

import 'package:expect/expect.dart';

import 'package:utf/utf.dart';
import 'package:utf/src/util.dart';

void main() {
  testCodepointsToUtf16CodeUnits();
  testUtf16bytesToCodepoints();
}

void testCodepointsToUtf16CodeUnits() {
  // boundary conditions
  Expect.listEquals([], codepointsToUtf16CodeUnits([]), "no input");
  Expect.listEquals([0x0], codepointsToUtf16CodeUnits([0x0]), "0");
  Expect.listEquals([0xd800, 0xdc00],
      codepointsToUtf16CodeUnits([0x10000]), "10000");

  Expect.listEquals([0xffff],
      codepointsToUtf16CodeUnits([0xffff]), "ffff");
  Expect.listEquals([0xdbff, 0xdfff],
      codepointsToUtf16CodeUnits([0x10ffff]), "10ffff");

  Expect.listEquals([0xd7ff],
      codepointsToUtf16CodeUnits([0xd7ff]), "d7ff");
  Expect.listEquals([0xe000],
      codepointsToUtf16CodeUnits([0xe000]), "e000");

  Expect.listEquals([UNICODE_REPLACEMENT_CHARACTER_CODEPOINT],
      codepointsToUtf16CodeUnits([0xd800]), "d800");
  Expect.listEquals([UNICODE_REPLACEMENT_CHARACTER_CODEPOINT],
      codepointsToUtf16CodeUnits([0xdfff]), "dfff");
}

void testUtf16bytesToCodepoints() {
  // boundary conditions: First possible values
  Expect.listEquals([], utf16CodeUnitsToCodepoints([]), "no input");
  Expect.listEquals([0x0], utf16CodeUnitsToCodepoints([0x0]), "0");
  Expect.listEquals([0x10000],
      utf16CodeUnitsToCodepoints([0xd800, 0xdc00]), "10000");

  // boundary conditions: Last possible sequence of a certain length
  Expect.listEquals([0xffff],
      utf16CodeUnitsToCodepoints([0xffff]), "ffff");
  Expect.listEquals([0x10ffff],
      utf16CodeUnitsToCodepoints([0xdbff, 0xdfff]), "10ffff");

  // other boundary conditions
  Expect.listEquals([0xd7ff],
      utf16CodeUnitsToCodepoints([0xd7ff]), "d7ff");
  Expect.listEquals([0xe000],
      utf16CodeUnitsToCodepoints([0xe000]), "e000");

  // unexpected continuation bytes
  Expect.listEquals([0xfffd],
      utf16CodeUnitsToCodepoints([0xdc00]),
      "dc00 first unexpected continuation byte");
  Expect.listEquals([0xfffd],
      utf16CodeUnitsToCodepoints([0xdfff]),
      "dfff last unexpected continuation byte");
  Expect.listEquals([0xfffd],
      utf16CodeUnitsToCodepoints([0xdc00]),
      "1 unexpected continuation bytes");
  Expect.listEquals([0xfffd, 0xfffd],
      utf16CodeUnitsToCodepoints([0xdc00, 0xdc00]),
      "2 unexpected continuation bytes");
  Expect.listEquals([0xfffd, 0xfffd ,0xfffd],
      utf16CodeUnitsToCodepoints([0xdc00, 0xdc00, 0xdc00]),
      "3 unexpected continuation bytes");

  // incomplete sequences
  Expect.listEquals([0xfffd], utf16CodeUnitsToCodepoints([0xd800]),
      "d800 last byte missing");
  Expect.listEquals([0xfffd], utf16CodeUnitsToCodepoints([0xdbff]),
      "dbff last byte missing");

  // concatenation of incomplete sequences
  Expect.listEquals([0xfffd, 0xfffd],
      utf16CodeUnitsToCodepoints([0xd800, 0xdbff]),
      "d800 dbff last byte missing");

  // impossible bytes
  Expect.listEquals([0xfffd], utf16CodeUnitsToCodepoints([0x110000]),
      "110000 out of bounds");

  // overlong sequences not possible in utf16 (nothing < x10000)
  // illegal code positions d800-dfff not encodable (< x10000)
}
