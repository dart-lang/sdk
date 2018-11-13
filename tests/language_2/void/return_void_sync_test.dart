// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void voidValue = null;

void main() {
  test0();
  test1();
  test2();
  test3();
}

// Testing that a block bodied function may have an empty return
void test0() {
  return;
}

// Testing that a block bodied function may have no return
void test1() {}

// Testing that a block bodied function may return void
void test2() {
  return voidValue;
}

// Testing that a block bodied function may have both empty returns
// and void returning paths
void test3([bool b]) {
  if (b == null) {
    return;
  } else if (b) {
    return voidValue;
  }
}
