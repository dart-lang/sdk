// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// There is no unary plus operator in Dart.

main() {
  var a = 1;
  var b = +a;
  //      ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
  // [cfe] '+' is not a prefix operator.
}
