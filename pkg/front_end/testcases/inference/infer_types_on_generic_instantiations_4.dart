// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

class A<T> {
  T x = throw '';
}

class B<E> extends A<E> {
  E y = throw '';
  get x => y;
}

foo() {
  int y = /*error:INVALID_ASSIGNMENT*/ new B<String>().x;
  String z = new B<String>().x;
}

main() {
  foo();
}
