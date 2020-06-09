// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

void voidValue = null;

void main() {
  test1();
  test2();
  test3();
  test4();
}

// Testing that a block bodied function may have no return
Future<FutureOr<void>>? test1() {}

// Testing that a block bodied function may return Future<void>
Future<FutureOr<void>>? test2() {
  return null as Future<void>?;
}

// Testing that a block bodied function may return FutureOr<void>
Future<FutureOr<void>>? test3() {
  return null as Future<FutureOr<void>>?;
}

// Testing that a block bodied function may return non-void Future values
Future<FutureOr<void>> test4() {
  return new Future.value(42);
}
