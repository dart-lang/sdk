// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library is1_test;

import 'test_base.dart';

class N {}

class I extends N {}

class D extends N {}

class A<T> {}

main() {
  var x = new A<I>();
  expectTrue(x is A<N>);
  expectTrue(x is A<I>);
  expectFalse(x is A<D>);

  var y = new A();
  expectTrue(y is A<N>);
  expectTrue(y is A<I>);
  expectTrue(y is A<D>);
}
