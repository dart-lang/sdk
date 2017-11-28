// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 20840.

class SomeClass {
  Object someField;

  SomeClass() {
    [1].forEach((o) => someMethod());
    someField = new Object();
  }

  void someMethod() {
    if (someField != null) {
      throw "FAIL";
    }
  }
}

void main() {
  new SomeClass();
}
