// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library field_initializer2_test;

import 'test_base.dart';

class A<T> {}

class B<T> {
  var x = new A<T>();
  var y;
  B() : y = new A<T>();
}

main() {
  var b = new B<A>();
  expectTrue(b.x is A<A>);
  expectTrue(b.y is A<A>);

  expectFalse(b.x is A<B>);
  expectFalse(b.y is A<B>);
}
