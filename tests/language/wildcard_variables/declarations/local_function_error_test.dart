// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A local function declaration named `_` is non-binding and cannot be accessed.

// SharedOptions=--enable-experiment=wildcard-variables

void main() {
  void _() {}

  /*indent*/ _();
  //         ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_FUNCTION
  // [cfe] Method not found: '_'.
}
