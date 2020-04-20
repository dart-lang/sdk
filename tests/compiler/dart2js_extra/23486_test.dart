// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Regression test for http://dartbug.com/23486
//
// Dart2js used to crash when using `super` and prefixes inside parenthesized
// expressions.
import 'package:expect/expect.dart';

import '23486_helper.dart' as p;

class B {
  var field = 1;
}

class A extends B {
  m() {
    (super).field = 1; //# 01: compile-time error
  }
}

class C {
  C();
  C.name();
}

class D extends C {
  D() : super();
  D.name() : (super).name(); //# 02: compile-time error
}

main() {
  Expect.throws(new A().m); //       //# 01: continued
  Expect.throws(() => new D.name()); //# 02: continued
  Expect.throws(() => (p).x); //     //# 03: compile-time error
}
