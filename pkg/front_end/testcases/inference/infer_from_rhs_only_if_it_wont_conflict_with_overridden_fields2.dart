// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class A {
  final x = null;
}

class B implements A {
  final x = 2;
}

foo() {
  String y = /*info:DYNAMIC_CAST*/ new B(). /*@target=B.x*/ x;
  int z = /*info:DYNAMIC_CAST*/ new B(). /*@target=B.x*/ x;
}

main() {}
