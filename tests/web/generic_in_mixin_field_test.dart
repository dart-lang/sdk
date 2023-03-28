// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(https://github.com/dart-lang/sdk/issues/51557): Decide if the mixins
// being applied in this test should be "mixin", "mixin class" or the test
// should be left at 2.19.
// @dart=2.19

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
