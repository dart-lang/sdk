// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

class A<T> {
  final T x = throw '';
  final T w = throw '';
}

class B implements A<int> {
  get x => 3;
  get w => /*error:RETURN_OF_INVALID_TYPE*/ "hello";
}

foo() {
  String y = /*error:INVALID_ASSIGNMENT*/ new B().x;
  int z = new B().x;
}

main() {}
