// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

class C {
  T m<T>(T x) => x;
}

class D extends C {
  m(x) => x;
}

test() {
  int y = /*info:DYNAMIC_CAST*/ new D()
      . /*error:WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD*/ m<int>(42);
  print(y);
}

main() {}
