// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// The interpolated identifier must start with an identifier start character.

main() {
  var x = 1;
  var s = "eins und $-x macht zwei.";
  //                 ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
  // [cfe] A '$' has special meaning inside a string, and must be followed by an identifier or an expression in curly braces ({}).
}
