// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  void foo({String s = 'hi'}) {
    print(s);
  }
}

class B extends A {
  @override
  void foo({String s = 'there'}) {
    print(s);
  }
}

A getA(int x) {
  if (x < 10) {
    return B();
  } else {
    // A is instantiated but the type cannot flow into a 'foo' call so A.foo's
    // body is not reachable.
    throw 'here';
    return A();
  }
}

void main() {
  getA(9).foo();
  // Ensure the default value is not inlined into the function.
  getA(8).foo(s: 'wow');
}
