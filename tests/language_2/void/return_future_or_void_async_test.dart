// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

void voidValue = null;

void main() {
  test0();
  test1();
  test2();
  test3();
  test4();
  test5();
}

// Testing that a block bodied function may have an empty return
FutureOr<void> test0() async {
  return;
}

// Testing that a block bodied function may have no return
FutureOr<void> test1() async {}

// Testing that a block bodied function may return Future<void>
FutureOr<void> test2() async {
  return null as Future<void>;
}

// Testing that a block bodied function may return FutureOr<void>
FutureOr<void> test3() async {
  return null as FutureOr<void>;
}

// Testing that a block bodied async function may return non-void
// values
FutureOr<void> test4() async {
  return 42;
}

// Testing that a block bodied async function may return non-void
// Future values
FutureOr<void> test5() async {
  return new Future.value(42);
}
