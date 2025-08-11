// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  const A();
  const factory A.redir() = A;
}

enum E {
  element(A.redir());

  const E(A a);
}

main() {}
