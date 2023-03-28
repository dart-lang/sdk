// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(51557): Decide if the mixins being applied in this test should be
// "mixin", "mixin class" or the test should be left at 2.19.
// @dart=2.19

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
