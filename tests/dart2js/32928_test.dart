// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions=--strong

/// Regression test for issue 32928.

abstract class A<T> {
  set f(T value) {
    print(value);
  }
}

abstract class B extends A {}

class C extends B {
  m(value) => super.f = value;
}

main() {
  new C().m(null);
}
