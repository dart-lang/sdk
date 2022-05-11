// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

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
    throw "Evil hashCode";
  }
}

main() {
  // Test that when using an instance of a custom class as a key in a const Map,
  // its hash code is computed as its identity hash, and even if the class
  // overrides `hashCode`, that `hashCode` implementation is not called.
  final map = const {1: 42, 'foo': 499, 2: 'bar', Nasty(1): 'baz'};
  Expect.equals(42, map[getValueNonOptimized(1.0)]);
  Expect.equals(
      499, map[getValueNonOptimized(new String.fromCharCodes('foo'.runes))]);
  Expect.equals('bar', map[getValueNonOptimized(2)]);
  Expect.isNull(map[getValueNonOptimized(Nasty(1))]);
  Expect.equals('baz', map[getValueNonOptimized(const Nasty(1))]);
}
