// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:async';

void main() {
  test();
}

// Testing that a block bodied function may not have an empty return
Future<FutureOr<void>> test() {
  return;
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.RETURN_WITHOUT_VALUE
// [cfe] Must explicitly return a value from a non-void function.
}
