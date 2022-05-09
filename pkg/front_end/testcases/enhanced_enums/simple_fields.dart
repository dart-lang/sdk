// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum E1 {
  one(1),
  two.named(2);

  final int foo;

  const E1(this.foo);

  const E1.named(int value) : foo = value;
}

enum E2<X, Y> {
  one<int, String>(1, "one"),
  two.named("two", 2),
  three.named("three", "three");

  final X foo;
  final Y bar;

  const E2(this.foo, this.bar);
  const E2.named(Y this.bar, X this.foo);
}

main() {}
