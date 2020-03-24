// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Test calling convention of property extraction closures (super edition).
library bound_closure_super_test;

import 'package:expect/expect.dart';

import 'bound_closure_test.dart' as bound_closure_test;

import 'bound_closure_test.dart' show inscrutable, makeCC;

main() {
  // Calling main from bound_closure_test.dart to set up native code.
  bound_closure_test.main();

  var c = inscrutable(makeCC)();
  var csfoo = inscrutable(c).superfoo;

  Expect.equals('BB.foo(1, B)', csfoo(1));
  Expect.equals('BB.foo(2, 3)', csfoo(2, 3));
}
