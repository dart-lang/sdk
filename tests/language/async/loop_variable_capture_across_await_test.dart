// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Each loop iteration has its own copy of the variables declared in it, so a
// closure keeps the value from the iteration that created it. This must also
// hold when a `while` loop contains an `await` or a `yield`.

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';

Future<List<int Function()>> asyncLoop() async {
  final closures = <int Function()>[];
  var i = 0;
  while (i < 3) {
    // Ensure each closure gets its own `x`.
    final x = await Future.value(i++);
    closures.add(() => x);
  }
  return closures;
}

Iterable<int Function()> syncStarLoop() sync* {
  var i = 0;
  while (i < 3) {
    // Ensure each closure gets its own `x`.
    final x = i++;
    yield () => x;
  }
}

void check(List<int Function()> closures) {
  Expect.listEquals([0, 1, 2], [for (final c in closures) c()]);
}

void main() {
  asyncTest(() async {
    check(await asyncLoop());
    check(syncStarLoop().toList());
  });
}
