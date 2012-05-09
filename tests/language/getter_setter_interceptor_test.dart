// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  int length = 0;

  foo() => length++;
  bar() => ++length;
}

main() {
  Expect.equals(0, new A().foo());
  Expect.equals(1, new A().bar());
}
