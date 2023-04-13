// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:collection';
import 'package:expect/expect.dart';

class ThrowingCurrentIterator implements Iterator<int> {
  int _remaining;
  ThrowingCurrentIterator(this._remaining);

  bool moveNext() => _remaining-- > 0;
  int get current => throw 'current';
}

class ThrowingCurrent extends IterableBase<int> {
  final int _length;
  ThrowingCurrent(this._length);
  Iterator<int> get iterator => ThrowingCurrentIterator(_length);
}

Iterable<int> f1() sync* {
  yield* ThrowingCurrent(5);
  yield* ThrowingCurrent(5);
}

Iterable<int> f2() sync* {
  yield* f1();
  yield* f1();
}

main() {
  // `IterableBase.length` uses only `moveNext()`.
  Expect.equals(5, ThrowingCurrent(5).length);

  // The spec dictates that `yield*` calls `moveNext()` and `current` for each
  // element in order to add the value to the iterable associated with the
  // generator.
  final i1 = f1().iterator;
  Expect.throws(() => i1.moveNext());

  // Further calls to `moveNext()` must return false (17.15).
  Expect.isFalse(i1.moveNext());

  // Same tests but for nested `yield*`.
  final i2 = f2().iterator;
  Expect.throws(() => i2.moveNext());
  Expect.isFalse(i2.moveNext());

  // Slighly surprising consequence of the specified behavior.
  Expect.throws(() => f1().length);
  Expect.throws(() => f2().length);
}
