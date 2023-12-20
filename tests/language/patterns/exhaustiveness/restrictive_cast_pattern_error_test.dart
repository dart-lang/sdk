// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test exercises a soundness bug in language version <= 3.2.

sealed class S {
  bool get b;
}

class A implements S {
  final bool b;

  A(this.b);
}

class B implements S {
  final bool b;

  B(this.b);
}

class C implements A, B {
  bool get b => false;
}

int? value = 1;

int? method(S s) => switch (s) {
//                  ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_EXPRESSION
//                          ^
// [cfe] The type 'S' is not exhaustively matched by the switch cases since it doesn't match 'A(b: false)'.
      A(b: true) as A => 0,
      B(b: true) as B => value,
    };

main() {
  print(method(C()));
}
