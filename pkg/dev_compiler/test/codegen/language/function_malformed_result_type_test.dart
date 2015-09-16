// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test for a function with a malformed result type.

import "package:expect/expect.dart";

class C<T, U> {}

main() {
  {
    C<int> f() => null;
    bool got_type_error = false;
    try {
      f();
    } on TypeError catch (error) {
      got_type_error = true;
    }
    // No type error expected, since returned null is not type checked.
    Expect.isFalse(got_type_error);
  }
  {
    C<int> f() => new C<int, String>();
    bool got_type_error = false;
    try {
      f();
    } on TypeError catch (error) {
      got_type_error = true;
    }
    // Type error not expected in production nor checked mode since C<int>
    // is handled like C<dynamic,dynamic>.
    Expect.isFalse(got_type_error);
  }
}
