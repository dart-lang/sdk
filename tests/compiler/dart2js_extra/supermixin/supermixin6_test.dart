// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';

class SuperA {
  int field = 0;

  set setter(int a) => field = a;
}

class SuperB extends SuperA {
  set setter(int a) => field = a + 1;
}

mixin Mixin on SuperA {
  set setter(int a) => super.setter = a;
}

class Class = SuperB with Mixin;

main() {
  var c = new Class();
  c.setter = 41;
  Expect.equals(42, c.field);
}
