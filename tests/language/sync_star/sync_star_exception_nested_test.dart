// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// See: https://github.com/dart-lang/sdk/issues/42466

import 'dart:collection';
import 'package:expect/expect.dart';

String? caughtString;

a() sync* {
  yield 3;
  throw 'Throw from a()';
  yield 4;
}

b() sync* {
  yield 2;
  yield* a();
  yield 5;
}

c() sync* {
  try {
    yield 1;
    yield* b();
    yield 6;
  } catch (e, st) {
    caughtString = 'Caught in c()';
  }
}

d() sync* {
  try {
    yield 0;
    yield* c();
    yield 7;
  } catch (e, st) {
    caughtString = 'Caught in d()';
  }
}

main() {
  List yields = [];
  try {
    for (final e in d()) {
      yields.add(e);
    }
  } catch (e, st) {
    caughtString = 'Caught in main()';
  }
  Expect.equals('Caught in c()', caughtString);
  Expect.listEquals([0, 1, 2, 3, 7], yields);
}
