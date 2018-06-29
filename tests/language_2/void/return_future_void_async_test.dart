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
  test6();
}

// Testing that a block bodied async function may have an empty return
Future<void> test0() async {
  return;
}

// Testing that a block bodied async function may have no return
Future<void> test1() async {}

// Testing that a block bodied async function may return Future<void>
Future<void> test2([bool b]) async {
  return null as Future<void>;
}

// Testing that a block bodied async function may return FutureOr<void>
Future<void> test3([bool b]) async {
  return null as FutureOr<void>;
}

// Testing that a block bodied async function may return null
Future<void> test4([bool b]) async {
  return null;
}

// Testing that a block bodied async function may return dynamic
Future<void> test5([bool b]) async {
  return null as dynamic;
}

// Testing that a block bodied async function return void
Future<void> test6() async {
  return voidValue;
}
