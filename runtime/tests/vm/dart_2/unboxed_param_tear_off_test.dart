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

@pragma('vm:never-inline')
int bar(int i, Foo foo, double j) {
  triggerGc();
  globalFoo.val = 0;
  return i + 2 + j.toInt() - j.toInt() + foo.val;
}

@pragma('vm:never-inline')
createFoo() {
  globalFoo = Foo(1);
}

final bool kTrue = int.parse('1') == 1;

@pragma('vm:never-inline')
testExecution(func, double param) {
  Expect.equals(3, func(kTrue ? 1 : 2, globalFoo, kTrue ? param : 1.0));
}

main() {
  createFoo();
  final dbl = getDoubleWithHeapObjectTag();
  testExecution(bar, dbl);
}
