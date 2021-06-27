// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/// Regression test for mixin overrides (dartbug.com/44636).
///
/// Prior to the fix, B's initializer was accidentally being applied on the
/// overriden definition in C, and as a result, the program would stack
/// overflow.
import 'package:expect/expect.dart';

class A = B with C;

mixin M {}

abstract class B with M {
  Object _test = "a";
}

mixin C on B, M {
  @override
  Object get _test => super._test;

  @override
  set _test(Object value) {
    super._test = value;
  }
}

main() => Expect.equals("a", A()._test);
