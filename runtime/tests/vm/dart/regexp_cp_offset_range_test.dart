// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that RegExps whose character offsets don't fit into the offset
// operand of the RegExp bytecode either match normally or are rejected as too
// large, instead of being compiled with a truncated offset.
//
// The patterns are from V8's test/mjsunit/regress/regress-499721612.js and
// test/mjsunit/regress/regress-503097371.js.

import 'package:expect/expect.dart';

void testNoMatch(String pattern, String subject) {
  try {
    Expect.isNull(RegExp(pattern).firstMatch(subject));
  } on FormatException catch (e) {
    Expect.isTrue(e.message.contains('Regular expression too large'));
  }
}

main() {
  final pre = "(?:(?:" + "a" * 5460 + "){2}){3}";
  testNoMatch(pre + "(?:b{100}|c{100})d", "a" * 65536);

  final preBackward = "(?:(?:" + "a" * 5461 + "){2}){3}";
  testNoMatch("(?<=bb" + preBackward + ")c", "c");
}
