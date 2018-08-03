// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
class A {
  int call(int x) => x * 2;
}

class B extends A {
  int call(int x) => x * 3;

  int call_super() {
    // Assumes that super() means super.call().
    // In reality, it is illegal to use it this way.
    return super(5);
  }
}

main() {
  assert(new B().call_super() == 10);
}
