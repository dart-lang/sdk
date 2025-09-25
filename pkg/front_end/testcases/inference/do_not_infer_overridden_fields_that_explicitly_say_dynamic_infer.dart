// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

class A {
  final int x = 2;
}

class B implements A {
  /*error:INVALID_METHOD_OVERRIDE*/
  dynamic get x => 3;
}

foo() {
  String y = /*info:DYNAMIC_CAST*/ new B().x; // TypeError.
  int z = /*info:DYNAMIC_CAST*/ new B().x;
}

main() {
  try {
    foo();
  } on TypeError {}
}
