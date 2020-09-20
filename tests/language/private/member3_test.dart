// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'member3_lib.dart';

class A {}

class Test extends B {
  test() {
    _fun();
//  ^^^^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
// [cfe] The method '_fun' isn't defined for the class 'Test'.
  }
}

void main() {
  Test().test();
}
