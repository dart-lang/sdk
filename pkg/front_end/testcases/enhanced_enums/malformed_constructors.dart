// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum E1 {
  element;

  E1(); // Error.
  E1.named(); // Error.
}

enum E2 {
  one.named1(),
  two.named2();

  const E2.named1() : super(); // Error.
  const E2.named2() : super(42, "42"); // Error.
}

main() {}
