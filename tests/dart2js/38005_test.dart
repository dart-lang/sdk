// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {}

int foo<T>() {
  switch (T) {
    case A:
      return 42;
    default:
      return -1;
  }
}

void main() {
  Expect.equals(42, foo<A>());
  Expect.equals(-1, foo<int>());
}
