// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library closure2_test;

import 'test_base.dart';

class A<T> {
  fun() => (o) => o is T;
}

class X {}

class Y {}

main() {
  var tester = new A<X>().fun();

  expectTrue(tester(new X()));
  expectFalse(tester(new Y()));
}
