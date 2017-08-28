// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  final _x;
  const A.a1(
      String //# 01: compile-time error
          x)
      : this.a2(x);
  const A.a2(
      String //# 02: compile-time error
          x)
      : this.a3(x);
  const A.a3(
      String //# 03: compile-time error
          x)
      : _x = x;
}

use(x) => x;

main() {
  use(const A.a1(0));
}
