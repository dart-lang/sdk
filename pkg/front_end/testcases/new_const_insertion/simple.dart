// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test checks that new/const insertion works for some simple cases.

class A {
  final int x;
  const A(this.x);
}

main() {
  int foo = 42;
  A(5);
  A(5 + 5);
  A(foo);
  A(5 + foo);
}
