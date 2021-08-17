// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/46867

import 'package:expect/expect.dart';

class Interface {
  covariant Object x = 'from Interface';
}

mixin Mixin implements Interface {}

class BaseClass {
  static var getterCallCount = 0;
  static var setterCallCount = 0;
  Object get x => getterCallCount++;
  set x(Object value) => setterCallCount++;
}

class SubClass extends BaseClass with Mixin {}

void main() {
  Expect.equals(0, BaseClass.getterCallCount);
  SubClass().x;
  Expect.equals(1, BaseClass.getterCallCount);

  Expect.equals(0, BaseClass.setterCallCount);
  SubClass().x = 42;
  Expect.equals(1, BaseClass.setterCallCount);
}
