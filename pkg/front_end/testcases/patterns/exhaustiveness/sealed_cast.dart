// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

sealed class M {}

class A extends M {}

class B extends M {}

class C extends M {}

class D implements A, B {}

method(M m) => switch (m) {
      A() as B => 0,
      B() => 1,
    };

main() {
  method(B());
  method(D());
}
