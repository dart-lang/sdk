// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class SuperA {
  get getter => 'A';
}

class SuperB extends SuperA {
  get getter => 'B';
}

mixin Mixin on SuperA {
  get getter => super.getter;
}

class Class extends SuperB with Mixin {}

main() {
  var c = new Class();
  Expect.equals("B", c.getter);
}
