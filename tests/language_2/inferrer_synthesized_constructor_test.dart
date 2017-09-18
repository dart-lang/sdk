// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js's type inferrer that used to not
// propagate default types in synthesized calls.

import "package:expect/expect.dart";

class A {
  final x;
  A([this.x = 'foo']);
}

class B extends A {
  // The synthesized constructor was not saying that it would call
  // [A]'s constructor with its default type.
}

main() {
  // By calling [B]'s constructor with an int parameter, the inferrer
  // used to only see this call and consider the [A.x] field to always
  // be int.
  Expect.equals(84, new A(42).x + 42);
  Expect.throwsTypeError(() => new B().x + 42);
}
