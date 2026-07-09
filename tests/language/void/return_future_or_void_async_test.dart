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
  test6();
}

// Testing that a block bodied function may have an empty return
FutureOr<void> test0() async {
  return;
}

// Testing that a block bodied function may have no return
FutureOr<void> test1() async {}

// Testing that a block bodied function may return Future<void>
FutureOr<void> test2() async {
  return Future<void>.value(null);
}

// Testing that a block bodied function may return FutureOr<void>
FutureOr<void> test3() async {
  return null as FutureOr<void>;
}

// Testing that a block bodied function may return void
FutureOr<void> test6() async {
  return voidValue;
}
