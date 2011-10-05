// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that one cannot access a static field through super.

class A {
  static var x;
}

class B {
  foo() {
    return super.x;
  }
}
