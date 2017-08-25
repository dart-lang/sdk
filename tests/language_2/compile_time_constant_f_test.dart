// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  final x;
  const A(this.x);
  const A.named([this.x]);
  const A.named2([this.x = 2]);
}

const a1 = const A(0);
const a2 = const A.named();
const a3 = const A.named(1);
const a4 = const A.named2();
const a5 = const A.named2(3);

main() {
  Expect.equals(0, a1.x);
  Expect.equals(null, a2.x);
  Expect.equals(1, a3.x);
  Expect.equals(2, a4.x);
  Expect.equals(3, a5.x);
}
