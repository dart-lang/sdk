// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart spec 0.03, section 11.10 - generative constructors can only have return
// statements in the form 'return;'.
class A {
  int x;
  A(this.x) { return; } // 'return;' is equivalent to 'return this;'
  int foo(int y) => x + y;
}

main() {
  Expect.equals((new A(1)).foo(10), 11);
}
