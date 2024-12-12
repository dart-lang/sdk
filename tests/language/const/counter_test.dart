// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Bug: 4254106 Constant constructors must have (implicit) const parameters.

class ConstCounter {
  const ConstCounter(int i) : nextValue_ = (() => i + 1);
  //                                        ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_CONSTANT
  // [cfe] Not a constant expression.
  final nextValue_;
}

main() {
  const ConstCounter(3);
  // [error column 3, length 21]
  // [analyzer] COMPILE_TIME_ERROR.INVALID_CONSTANT
}
