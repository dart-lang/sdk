// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The purpose of this test is to detect that no unnecessary contexts are
// created when a constructor parameter is used in its field initializers.  No
// contexts should be created either in the initializer or in the constructor
// body.

class X {}

class A {
  X x;
  A(this.x) {}
}

main() {
  A a = new A(new X());
}
