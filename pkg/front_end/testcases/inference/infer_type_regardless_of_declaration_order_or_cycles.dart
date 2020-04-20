// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'infer_type_regardless_of_declaration_order_or_cycles_b.dart';

class C extends B {
  get x => null;
}

class A {
  int get x => 0;
}

foo() {
  int y = new C(). /*@target=C::x*/ x;
  String z = /*error:INVALID_ASSIGNMENT*/ new C(). /*@target=C::x*/ x;
}

main() {
  foo();
}
