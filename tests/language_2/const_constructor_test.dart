// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A<T> {
  final int x;
  const A.named() : x = 42;
  A() : x = null;
}

main() {
  Expect.equals(42, (const A<int>.named()).x);
  Expect.equals(42, (new A<int>.named()).x);
  const A<int>(); //# 01: compile-time error
}
