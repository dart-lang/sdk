// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

T f<T>() => throw '';

class C<T> {
  const C();
}

void test(C<int> x) {
  switch (x) {
    case const C():
      var y = 0;
      break;
    default:
      var y = 0;
      break;
  }
}

main() {}
