// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that an unresolved method call in a factory is a compile error.

class A {
  factory A() {
    foo(); /*@compile-error=unspecified*/
  }
}

main() {
  new A();
}
