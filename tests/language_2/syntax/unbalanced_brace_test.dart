// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test syntax errors related to unterminated braces.

class A {
  m() {
  /* //# 01: syntax error
  }
  // */

/* //# 02: syntax error
}
// */

class B {}

main() {
  new A();
  new B();
}
