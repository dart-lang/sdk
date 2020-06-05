// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

void voidValue = null;

void main() {
  test1();
  test4();
  test5();
  test6();
  test7();
  test8();
}

// Testing that a block bodied async function may have no return
Future<FutureOr<void>> test1() async {}

// Testing that a block bodied async function may return Future<FutureOr<void>>
Future<FutureOr<void>> test4([bool? b]) async {
  return Future<FutureOr<void>>.value(null);
}

// Testing that a block bodied async function may return Future<Future<void>>
Future<FutureOr<void>> test5([bool? b]) async {
  return Future<Future<void>>.value(Future<void>.value(null));
}

// Testing that a block bodied async function may return FutureOr<Future<void>>
Future<FutureOr<void>> test6([bool? b]) async {
  return Future<void>.value(null) as FutureOr<Future<void>>;
}

// Testing that a block bodied async function may return non-void
// values
Future<FutureOr<void>> test7() async {
  return 42;
}

// Testing that a block bodied async function may return non-void
// Future values
Future<FutureOr<void>> test8() async {
  return new Future<int>.value(42);
}
