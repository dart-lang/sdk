// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class SuperA {
  method(a) => 'A$a';
}

class SuperB implements SuperA {
  method(a) => 'B$a';
}

mixin Mixin on SuperA {
  method(a) => super.method('M$a');
}

class Class extends SuperB with Mixin {}

main() {
  var c = new Class();
  Expect.equals("BMC", c.method('C'));
} 