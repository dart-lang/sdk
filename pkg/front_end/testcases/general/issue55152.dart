// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<X> {
  const A();
  const factory A.redir() = A;
}

typedef TA<Y> = A<Y>;

enum E {
  // Should be resolved to `const A<String>()`.
  element(TA.redir());

  final A<String> a;

  const E(this.a);
}
