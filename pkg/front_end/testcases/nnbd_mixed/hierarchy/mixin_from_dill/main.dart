// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

import 'opt_in_lib1.dart';
import 'opt_in_lib2.dart';
import 'opt_out_lib.dart';

class Super {
  B get getter => new B();
  void set setter(A a) {}
}

class Class1 extends Super with Mixin1 {}

class Class2 extends Base with Mixin2 {}

main() {
  var c = new Class1();
  c.getter.property;
  c.setter = new B();
  testInterface2(new Mixin2());
}
