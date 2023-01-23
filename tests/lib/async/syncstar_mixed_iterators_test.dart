// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test that sync* correctly iterates through nested iterators of both
// the internal sync* iterable and generic Iterable types.

import "package:expect/expect.dart";

Iterable<int> outerSyncStar() sync* {
  yield 1;
  // internal sync* iterable:
  yield* innerSyncStar();
  yield 4;
  // Generic Iterable<int>:
  yield* [5, 6];
  //
  yield* emptySyncStar();
  yield 7;
}

Iterable<int> innerSyncStar() sync* {
  yield 2;
  yield* [];
  yield* [3];
}

Iterable<int> emptySyncStar() sync* {
  yield* [];
}

main() {
  Expect.listEquals([1, 2, 3, 4, 5, 6, 7], [...outerSyncStar()]);
}
