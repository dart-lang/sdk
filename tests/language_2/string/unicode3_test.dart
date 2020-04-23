// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Backslash xXX must have exactly 2 hex digits.

main() {
  var str = "Foo\x0";
  //            ^^^
  // [analyzer] SYNTACTIC_ERROR.INVALID_HEX_ESCAPE
  // [cfe] An escape sequence starting with '\x' must be followed by 2 hexadecimal digits.
  str = "Foo\xF Bar";
  //        ^^^
  // [analyzer] SYNTACTIC_ERROR.INVALID_HEX_ESCAPE
  // [cfe] An escape sequence starting with '\x' must be followed by 2 hexadecimal digits.
}
