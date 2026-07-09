// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/51190.

bool test1(Function x, Object y) => x == y;
bool test2(void Function() x, Object y) => x == y;

void foo1() {}
void foo2() {}

void main() {
  test1(foo1, foo1);
  test1(foo2, foo2);

  test2(foo1, foo2);
  test2(foo2, foo1);
}
