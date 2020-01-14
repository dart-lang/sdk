// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  final x;
  const A([x = 499]) : this.x = x;
}

class B extends A {
  const B();
  final z = 99;
}

class C extends B {
  const C(this.y);
  final y;
}

const v = const C(42);

main() {
  Expect.equals(42, v.y);
  Expect.equals(499, v.x);
  Expect.equals(99, v.z);
}
