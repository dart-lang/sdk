// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

main() {
  // When analyzing this, the class element for B hasn't tried to parse its
  // members and isn't yet malformed.
  new B<A>();
}


class A {
  foo() {
    // But now, the class element for B has become malformed (as hasParseError
    // is true).
    new B<A>();
  }
}

class B<T> {
  int i
}
