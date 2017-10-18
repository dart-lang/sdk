// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Make sure the engine does not infer the wrong type for [:A.foo:].

import "package:expect/expect.dart";

class A {
  foo() => this;
}

class B extends A {}

main() {
  Expect.isTrue(new B().foo() is B);
}
