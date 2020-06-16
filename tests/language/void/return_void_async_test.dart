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
void test0() async {
  return;
}

// Testing that a block bodied async function may have no return
void test1() async {}

// Testing that a block bodied async function may return void
void test2() async {
  return voidValue;
}

// Testing that a block bodied async function may have both empty returns
//  and void returning paths
void test3([bool? b]) async {
  if (b == null) {
    return;
  } else {
    return voidValue;
  }
}

// Testing that a block bodied async function may return Null
void test4() async {
  return null;
}

// Testing that a block bodied async function may return dynamic
void test5() async {
  return null as dynamic;
}

// Testing that a block bodied async function may return FutureOr<void>
void test6() async {
  return null as FutureOr<void>;
}
