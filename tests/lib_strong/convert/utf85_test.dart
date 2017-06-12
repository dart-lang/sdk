// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library utf8_test;

import "package:expect/expect.dart";
import 'dart:convert';

main() {
  for (int i = 0; i <= 0x10FFFF; i++) {
    if (i == UNICODE_BOM_CHARACTER_RUNE) continue;
    Expect.equals(
        i, UTF8.decode(UTF8.encode(new String.fromCharCode(i))).runes.first);
  }
}
