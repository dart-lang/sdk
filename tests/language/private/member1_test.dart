// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'member1_lib.dart';

class A {}

class Test extends B {
  test() {
    _instanceField = true;
//  ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
// [cfe] The setter '_instanceField' isn't defined for the class 'Test'.
  }
}

void main() {
  Test().test();
}
