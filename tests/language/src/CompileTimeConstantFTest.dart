// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  final x = 4;
  const A(this.x);
  const A.named([this.x]);
  const A.named2([this.x = 2]);
  const A.named3();
}

final a1 = const A(0);
final a2 = const A.named();
final a3 = const A.named(1);
final a4 = const A.named2();
final a5 = const A.named2(3);
final a6 = const A.named3();

main() {
  Expect.equals(0, a1.x);
  Expect.equals(null, a2.x);
  Expect.equals(1, a3.x);
  Expect.equals(2, a4.x);
  Expect.equals(3, a5.x);
  Expect.equals(4, a6.x);
}
