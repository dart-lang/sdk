// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  int? i;

  A() {
    final x = (1, 2, 3);
    // Ensure record access in super constructor gets serialized in context
    // of correct member.
    i = x.$1;
  }
}

class B extends A {}

main() {
  print(B().i);
}
