// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'package:expect/expect.dart';

class A {
  noSuchMethod() {}
//^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
// [cfe] The method 'A.noSuchMethod' has fewer positional arguments than those of overridden method 'Object.noSuchMethod'.
}

class C extends Object with A {
//    ^
// [cfe] Applying the mixin 'A' to 'Object' introduces an erroneous override of 'noSuchMethod'.
//                          ^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
  test() {
    print("Hello from test");
  }
}

main() {
  C c = new C();
  c.test();
  dynamic cc = c;
  Expect.throwsNoSuchMethodError(() => cc.doesntExist());
}
