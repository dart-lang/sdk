// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  foo({a, b}) {
    Expect.equals(0, a);
    Expect.equals(1, b);
  }
}

main() {
  A a = new A();
  a.foo(a: 0, b: 1);
  a.foo(b: 1, a: 0);
}
