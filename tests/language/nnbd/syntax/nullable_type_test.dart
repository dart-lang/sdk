// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-strong

// Test that the trailing "?" is accepted after all type syntaxes.  Verify that
// the compiler understands the resulting type to be nullable by trying to
// construct a list containing `null`.  Verify that the runtime understands the
// resulting type to be nullable by checking the reified list type.
import 'package:expect/expect.dart';
import 'dart:core';
import 'dart:core' as core;

main() {
  var x1 = <int?>[null];
  Expect.type<List<int?>>(x1);
  Expect.notType<List<int>>(x1);

  var x2 = <core.int?>[null];
  Expect.type<List<int?>>(x2);
  Expect.notType<List<int>>(x2);

  var x3 = <List<int>?>[null];
  Expect.type<List<List<int>?>>(x3);
  Expect.notType<List<List<int>>>(x3);

  var x4 = <void Function()?>[null];
  Expect.type<List<void Function()?>>(x4);
  Expect.notType<List<void Function()>>(x4);
}
