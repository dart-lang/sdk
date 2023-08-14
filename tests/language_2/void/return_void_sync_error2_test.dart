// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:async';

void main() {
  test();
}

// Testing that a block bodied function may not return FutureOr<void>
void test() {
  return null as FutureOr<void>;
  //     ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.RETURN_OF_INVALID_TYPE
  //          ^
  // [cfe] Can't return a value from a void function.
}
