// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test throws exception in the middle of the increment operation, the setter
// part of the instance field increment never completes.
// VMOptions=--optimization-counter-threshold=10 --no-background-compilation

main() {
  var a = new A();
  a.field = new A();
  for (int i = 0; i < 20; i++) {
    try {
      a.foo(i);
    } catch (e) {
      // Ignore.
    }
  }
}

class A {
  var field;
  foo(i) {
    field++; // throw exception
  }
}
