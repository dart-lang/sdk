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
  test5();
  test6();
}

// Testing that a block bodied function may have no return
FutureOr<FutureOr<void>> test1() {}

// Testing that a block bodied function may return Future<void>
FutureOr<FutureOr<void>> test2() {
  return null as Future<void>;
}

// Testing that a block bodied function may return FutureOr<void>
FutureOr<FutureOr<void>> test3() {
  return null as FutureOr<void>;
}

// Testing that a block bodied function may return Future<void>
FutureOr<FutureOr<void>> test4() {
  return null as Future<Future<void>>;
}

// Testing that a block bodied function may return non-void values
FutureOr<FutureOr<void>> test5() {
  return 42;
}

// Testing that a block bodied function may return non-void Future values
FutureOr<FutureOr<void>> test6() {
  return new Future.value(42);
}

// Testing that a block bodied function may return overly nested Future
// values
FutureOr<FutureOr<void>> test() {
  return null as Future<Future<Future<void>>>;
}
