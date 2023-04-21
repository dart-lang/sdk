// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:async';

void voidValue = null;

void main() {
  test();
}

// Testing that a block bodied async function may not return void
Future<FutureOr<void>> test() async {
  return voidValue;
  //     ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.RETURN_OF_INVALID_TYPE
  // [cfe] This expression has type 'void' and can't be used.
}
