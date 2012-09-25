// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  Expect.listEquals([], [].getRange(0, 0));
  Expect.listEquals([], const [].getRange(0, 0));

  Expect.listEquals([], [].getRange(-1, 0));
  Expect.listEquals([], const [].getRange(-1, 0));

  Expect.listEquals([1, 2], [1, 2].getRange(0, 2));
  Expect.listEquals([1, 2], const [1, 2].getRange(0, 2));

  Expect.listEquals([1], [1, 2].getRange(0, 1));
  Expect.listEquals([1], const [1, 2].getRange(0, 1));

  Expect.listEquals([2], [1, 2].getRange(1, 1));
  Expect.listEquals([2], const [1, 2].getRange(1, 1));

  Expect.listEquals([], [1, 2].getRange(0, 0));
  Expect.listEquals([], const [1, 2].getRange(0, 0));

  Expect.listEquals([2, 3], [1, 2, 3, 4].getRange(1, 2));
  Expect.listEquals([2, 3], const [1, 2, 3, 4].getRange(1, 2));

  Expect.listEquals([2, 3], [1, 2, 3, 4].getRange(1, 2));
  Expect.listEquals([2, 3], const [1, 2, 3, 4].getRange(1, 2));

  expectIAE(() => [].getRange(0, -1));
  expectIAE(() => const [].getRange(-1, -1));

  expectIOORE(() => [].getRange(-1, 1));
  expectIOORE(() => [].getRange(1, 1));
  expectIOORE(() => [1].getRange(0, 2));
  expectIOORE(() => [1].getRange(1, 1));
}

void expectIOORE(Function f) {
  Expect.throws(f, (e) => e is IndexOutOfRangeException);
}

void expectIAE(Function f) {
  Expect.throws(f, (e) => e is ArgumentError);
}
