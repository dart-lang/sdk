// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

import 'dart:async';

typedef int IntToInt(int i);

IntToInt a() {
  return (x) => x;
}

Future<IntToInt> b() async {
  // TODO(paulberry): this is broken due to bug 29689.
  return (x) => x;
}

Iterable<IntToInt> c() sync* {
  yield (x) => x;
}

Iterable<IntToInt> d() sync* {
  yield* [(x) => x];
}

Stream<IntToInt> e() async* {
  yield (x) => x;
}

Stream<IntToInt> f() async* {
  yield* new Stream.fromIterable([(x) => x]);
}

main() {}
