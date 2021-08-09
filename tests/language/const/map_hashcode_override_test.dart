// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

/// Returns its argument.
///
/// Prevents static optimizations and inlining.
@pragma('vm:never-inline')
@pragma('dart2js:noInline')
dynamic getValueNonOptimized(dynamic x) {
  // DateTime.now() cannot be predicted statically, never equal to 42.
  if (DateTime.now().millisecondsSinceEpoch == 42) {
    return getValueNonOptimized(2);
  }
  return x;
}

class Nasty {
  final int n;

  const Nasty(this.n);

  int get hashCode {
    while (true) {}
  }
}

main() {
  final map = const {1: 42, 'foo': 499, 2: 'bar', Nasty(1): 'baz'};
  Expect.equals(42, map[getValueNonOptimized(1.0)]);
  Expect.equals(
      499, map[getValueNonOptimized(new String.fromCharCodes('foo'.runes))]);
  Expect.equals('bar', map[getValueNonOptimized(2)]);
  Expect.isNull(map[getValueNonOptimized(Nasty(1))]);
  Expect.equals('baz', map[getValueNonOptimized(const Nasty(1))]);
}
