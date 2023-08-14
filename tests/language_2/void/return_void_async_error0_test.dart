// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

void main() {
  test();
}

// Testing that a block bodied async function may not return non-void non-top
// values
void test() async {
  return 3;
  //     ^
  // [analyzer] COMPILE_TIME_ERROR.RETURN_OF_INVALID_TYPE
  // [cfe] Can't return a value from a void function.
}
