// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Unicode escapes must refer to valid Unicode points and not surrogate
/// characters.

main() {
  var str = "Foo\u{FFFFFF}";
  //            ^^^^^^^^^
  // [analyzer] SYNTACTIC_ERROR.INVALID_CODE_POINT
  // [cfe] The escape sequence starting with '\u' isn't a valid code point.
  str = "Foo\uD800";
  str = "Foo\uDC00";
}
