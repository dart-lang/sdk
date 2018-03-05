// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class A {
  noSuchMethod() {} //                                   //# 01: compile-time error
}

class C extends Object with A {
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
