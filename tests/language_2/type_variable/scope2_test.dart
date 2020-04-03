// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test that malformed type arguments are treated as an error.

class Foo<T> {
  // T is not in scope for a static method.
  static Foo<T> m() { /*@compile-error=unspecified*/
    return new Foo();
  }
}

main() {}
