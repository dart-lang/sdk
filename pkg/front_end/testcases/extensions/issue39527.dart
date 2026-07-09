// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  int value = 0;
}

extension Extension1 on C {
  C operator [](int index) => this..value += index + 1;
  void operator []=(int index, C other) =>
      this.value += other.value + index + 1;
  C operator -(int val) => this;
}

main() {
  C c = C();
  // Original term that produces an unexpected error.
  --Extension1(c)[42];

  // The pre-decrement desugars as follows, which is also flagged as an error.
  Extension1(c)[42] -= 1;

  // The compound assignment desugars as follows, which is accepted.
  Extension1(c)[42] = Extension1(c)[42] - 1;
}
