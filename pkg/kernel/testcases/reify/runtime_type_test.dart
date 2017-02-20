// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library runtime_type_test;

import 'test_base.dart';

class A<T> {}

class X {}

class Y {}

bool eqt(a, b) => a.runtimeType == b.runtimeType;

main() {
  expectTrue(eqt(new A(), new A<dynamic>()));
  expectTrue(eqt(new A<X>(), new A<X>()));
  expectFalse(eqt(new A<X>(), new A()));
  expectFalse(eqt(new A<X>(), new A<Y>()));
}
