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

class B extends A {
  const B(x) : super(x + 10);
  const B.named_() : super.named();
  const B.named(x) : super.named(x + 10);
  const B.named2_() : super.named2();
  const B.named2(x) : super.named2(x + 10);
  const B.named3() : super.named3();
}

final b1 = const B(0);
final b2 = const B.named_();
final b3 = const B.named(1);
final b4 = const B.named2_();
final b5 = const B.named2(3);
final b6 = const B.named3();

main() {
  Expect.equals(10, b1.x);
  Expect.equals(null, b2.x);
  Expect.equals(11, b3.x);
  Expect.equals(2, b4.x);
  Expect.equals(13, b5.x);
  Expect.equals(4, b6.x);
}
