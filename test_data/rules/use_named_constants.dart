// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `dart test -N use_named_constants`
m() {
  A.zero; // OK
  const A(0); // LINT
  const a = A(0); // LINT

  const A(1); // LINT
}

class A {
  const A(this.value);
  final int value;

  static const zero = A(0); // OK
  static const _one = A(1); // OK
  static const zeroAgain = A(0); // OK
}
