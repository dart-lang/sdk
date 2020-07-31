// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  A.foo() {}
  factory A() => new A.foo();
}

main() {
  Expect.isTrue(new A() is A);
}
