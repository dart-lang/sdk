// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  int c1 = 1;
  int test() => 2;
}

main() {}

errors() {
  A? a1 = new A() as A?;
  a1.c1;
  a1.test;
}
