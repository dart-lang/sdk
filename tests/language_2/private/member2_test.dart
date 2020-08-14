// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'member2_lib.dart';

class A {}

class Test extends B {
  test() {
    _staticField = true;
//  ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
// [cfe] The setter '_staticField' isn't defined for the class 'Test'.
  }
}

void main() {
  Test().test();
}
