// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library native_types;

import 'test_base.dart';

abstract class C {}

class D {}

var foo = bar;
var bar = foo;

main() {
  expectTrue(1 is int);
  expectTrue(1 is! double);

  expectTrue(new List<int>() is List<int>);
  expectTrue(new List<int>() is! List<double>);
  expectTrue("hest" is String);
  expectTrue("hest" is! int);

  expectTrue(null is! String);
  expectTrue(null is dynamic);
  expectTrue(null is Object);

  expectTrue(true is bool);
  expectTrue(true is! int);

  // Test error and exception classes
  expectThrows(() => new C(), (e) => e is AbstractClassInstantiationError);

  /// 01: static type warning

  expectThrows(() => new D().foo(), (e) => e is NoSuchMethodError);

  /// 02: static type warning

  expectThrows(() => foo, (e) => e is CyclicInitializationError);

  expectThrows(() => [][1], (e) => e is RangeError);

  expectTrue(new UnsupportedError("") is UnsupportedError);

  expectTrue(new ArgumentError() is ArgumentError);

  expectTrue(
      new IntegerDivisionByZeroException() is IntegerDivisionByZeroException);
}
