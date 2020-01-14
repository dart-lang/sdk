// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that type variables in try-catch work.

import "package:expect/expect.dart";

class C<T> {
  C.foo();
  factory C() {
    try {
      return new C<T>.foo();
    } finally {}
  }
}

main() {
  var c = new C<int>();
  Expect.isTrue(c is C<int>);
  Expect.isFalse(c is C<String>);
}
