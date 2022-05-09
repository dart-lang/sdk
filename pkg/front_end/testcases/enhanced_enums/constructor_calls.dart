// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum E {
  one, // Ok.
  two.named(), // Ok.
  three.f(), // Error.
  four.f2(); // Error.

  const E();

  const E.named()
    : this(); // Ok.

  factory E.f() => values.first;

  factory E.f2() {
    return const E(); // Error.
  }

  const factory E.f3() = E; // Error.

  factory E.f4() = E; // Error.

  factory E.f5() = E.f; // Ok.

  factory E.f6(int value) = E.f; // Error.
}

test() {
  new E(); // Error.
  const E(); // Error.
  E.new; // Error.

  new E.named(); // Error.
  const E().named(); // Error.
  E.named; // Error.

  new E.f(); // Ok.
  const E.f(); // Error.
  E.f; // Ok.
}

main() {}
