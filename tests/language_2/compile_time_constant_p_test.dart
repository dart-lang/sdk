// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  const A(
    this.x //# 01: compile-time error
      );
  final x = null;
}

class B extends A {
  const B();
}

var b = const B();

main() {
  Expect.equals(null, b.x);
}
