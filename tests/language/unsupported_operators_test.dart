// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test handling of unsupported operators.

library unsupported_operators;

class C {
  m() {
    print(
          super === //# 01: compile-time error
        null);
    print(
          super !== //# 02: compile-time error
        null);
  }
}

void main() {
  new C().m();
  new C().m();
  print(
        "foo" === //# 03: compile-time error
      null);
  print(
        "foo" !== //# 04: compile-time error
      null);
}
