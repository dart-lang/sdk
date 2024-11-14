// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// NEXT LINE (NEL, 0x85) character is special in that some Unicode versions do
// not include it as a whitespace character.
//
// However all Dart backends handle it as a whitespace character. dart2js and
// dart2wasm do this by a calling JS (`String.prototype.trim` and its
// left/right variants) and doing post-processing. To check these
// implementations tests in this file mix the SPACE character with NEL in
// various positions.
//
// string_trim_lr_test.dart tests various NEL characters on the left and right,
// but they do not mix NEL with other whitespace characters.
// string_trim_test.dart tests do not test NEL.

import "package:expect/expect.dart";

const int space = 0x20;
const int nel = 0x85;
const int h = 0x68;
const int i = 0x69;

void main() {
  Expect.equals(
    "hi",
    String.fromCharCodes([space, nel, space, h, i]).trimLeft(),
  );
  Expect.equals(
    "hi",
    String.fromCharCodes([h, i, space, nel, space]).trimRight(),
  );
  Expect.equals(
    "hi",
    String.fromCharCodes([space, nel, space, h, i, space, nel, space]).trim(),
  );
}
