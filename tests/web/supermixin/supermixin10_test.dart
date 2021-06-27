// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class SuperA {
  method1(a) => 'A$a';
}

class SuperB extends SuperA {
  method1(a) => 'B$a';
}

mixin Mixin on SuperA {
  method1(a) => super.method1('M$a');
  method2(a) => 'M$a';
}

class Class extends SuperB with Mixin {}

main() {
  var c = new Class();
  Expect.equals("BMC", c.method1('C'));
  Expect.equals("MC", c.method2('C'));
}
