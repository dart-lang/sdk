// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests tree shaking of field initializer for a write-only field.
// Regression test for https://github.com/dart-lang/sdk/issues/35632.

class A {
  A() {
    print('A');
  }
}

var field = A();

class B {
  B() {
    print('B');
  }
}

class C {
  var instanceField = new B();
}

void main() {
  field = null;
  new C().instanceField = null;
}
