// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by b
// BSD-style license that can be found in the LICENSE file.

class A1 {
  const A1();
  const factory A1.named(A1 it) = E1.named; // Error.
}

extension type const E1(A1 it) {
  const E1.named(A1 it): this(it);
}

enum A2 {
  element;
  const A2();
  const factory A2.named(A2 it) = E2.named; // Error.
}

extension type const E2(A2 it) {
  const E2.named(A2 it): this(it);
}
