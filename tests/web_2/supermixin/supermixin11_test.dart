// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

class SuperA1 {
  method1(a) => 'A1.m1$a';
}

class SuperA2 {
  method2(a) => 'A2.m2$a';
}

class SuperA {
  method1(a) => 'A.m1$a';
  method2(a) => 'A.m2$a';
}

class SuperB1 extends SuperA implements SuperA1 {
  method1(a) => 'B1.m1$a';
}

class SuperB2 extends SuperB1 implements SuperA2 {
  method2(a) => 'B2.m2$a';
}

mixin Mixin on SuperA1, SuperA2 {
  method1(a) => super.method1('M$a');
  method2(a) => super.method2('M$a');
}

class Class extends SuperB2 with Mixin {}

main() {
  var c = new Class();
  Expect.equals("B1.m1MC", c.method1('C'));
  Expect.equals("B2.m2MC", c.method2('C'));
}
