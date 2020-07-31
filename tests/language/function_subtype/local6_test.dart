// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.
// VMOptions=--no-eliminate-type-checks

// Regression test for issue 12127.

class C<T> {
  void test() {
    void foo(T a) {}
  }
}

main() {
  new C<bool>().test();
}
