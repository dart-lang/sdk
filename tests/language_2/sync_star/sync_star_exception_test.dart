// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// See: https://github.com/dart-lang/sdk/issues/42466

import 'dart:collection';
import 'package:expect/expect.dart';

var caughtString;

class AlwaysThrowingIterator implements Iterator<int> {
  bool moveNext() => throw 'moveNext';
  int get current => throw 'current';
}

class AlwaysThrowing extends IterableBase<int> {
  Iterator<int> get iterator => AlwaysThrowingIterator();
}

Iterable<int> f() sync* {
  try {
    yield* AlwaysThrowing();
  } catch (e, st) {
    caughtString = 'caught $e in f';
  }
}

void g() {
  try {
    for (int x in f()) {
      print(x);
    }
  } catch (e, st) {
    caughtString = 'caught $e in g';
  }
}

main() {
  g();
  // The spec dictates that if `e` (moveNext, current) throws then `yield* e`
  // should throw.
  // I.e. even though the iteration is happening in `g`, the `yield*` is in `f`
  // so its catch should trigger.
  Expect.equals('caught moveNext in f', caughtString);
}
