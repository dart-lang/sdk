// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum E1 {
  one(1),
  two.named(2);

  final int foo;

  const E1(this.foo);
  const E1.named(int value) : this(value); // Ok.
}

enum E2 {
  one(1),
  two.named(2);

  final int foo;

  const E2(this.foo);
  const E2.named(int value) : this(value, value); // Error.
}

main() {}
