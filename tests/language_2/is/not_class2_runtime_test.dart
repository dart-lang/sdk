// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for catch that we expect a class after an 'is'. 'aa' is a
// malformed type and a type error should be thrown upon test.

import 'package:expect/expect.dart';

class A {
  const A();
}

class IsNotClass2NegativeTest {
  static testMain() {
    var a = new A();
    var aa = new A();




    return 0;
  }
}

main() {
  IsNotClass2NegativeTest.testMain();
}
