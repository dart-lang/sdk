// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Ensure that we prepare type variables for inlined mixin fields.

import 'package:expect/expect.dart';

class A<T> {}

class Mixin<T> {
  var field = new A<T>();

  m1() => field is A<int>;
  m2() => field is A<String>;
}

class SuperClass<T> extends Object with Mixin<T> {}

class Class extends SuperClass<int> {}

@pragma('dart2js:noInline')
createClass() => new Class();

main() {
  var c = createClass();
  Expect.isTrue(c.m1());
  Expect.isFalse(c.m2());
}
