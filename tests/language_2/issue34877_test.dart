// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test: ensure that async for loops remain async for loops when
// mixed in.

import 'dart:async';

abstract class _Mixin {
  Future<int> stuff(Stream<int> values) async {
    var total = 0;
    await for (var value in values) {
      total += value;
    }
    return total;
  }
}

class Implementation extends Object with _Mixin {}

void main() async {
  print(await Implementation().stuff(Stream.fromIterable([1, 2, 3])));
}
