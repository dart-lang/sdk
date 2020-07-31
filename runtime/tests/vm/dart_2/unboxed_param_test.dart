// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedObjects=ffi_test_functions

import 'package:expect/expect.dart';

import 'dylib_utils.dart';
import 'unboxed_parameter_helper.dart';

class Foo {
  int val;
  Foo(this.val);
}

var globalFoo;

final dbl2 = getDoubleWithHeapObjectTag();

@pragma('vm:never-inline')
double bar(int i, double k, Foo foo, double j, [int optional = 1]) {
  triggerGc();
  globalFoo.val = 0;
  return (i + 2 + j.toInt() - j.toInt() + globalFoo.val + optional).toDouble();
}

@pragma('vm:never-inline')
createFoo() {
  globalFoo = Foo(1);
}

final bool kTrue = int.parse('1') == 1;

main() {
  createFoo();
  final dbl = getDoubleWithHeapObjectTag();
  Expect.equals(4.0,
      bar(kTrue ? 1 : 2, kTrue ? 2 * dbl : 0.0, globalFoo, kTrue ? dbl : 1.0));
  Expect.equals(
      3.0,
      bar(kTrue ? 1 : 2, kTrue ? 2 * dbl : 0.0, globalFoo, kTrue ? dbl : 1.0,
          0));
}
