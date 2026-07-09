// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for r24720.

import 'package:expect/expect.dart';

class A<T> {}

class B extends A<int> {
  B() : this.foo();
  B.foo();
}

main() {
  Expect.isTrue(new B() is B);
  Expect.isTrue(new B() is A<int>);
  Expect.isFalse(new B() is A<String>);
}
