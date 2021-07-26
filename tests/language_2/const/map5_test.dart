// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests lookup of type literals of user-defined classes in const maps.

// @dart = 2.9

import 'package:expect/expect.dart';

class A {}

class C<T> {}

typedef F = T Function<T>();

const aType = A;
const fType = F;

main() {
  final map = const {A: 42, F: 2, 'asdf': 'fdsa'};
  Expect.equals(42, map[getValueNonOptimized(A)]);
  Expect.equals(42, map[getValueNonOptimized(aType)]);
  Expect.equals(2, map[getValueNonOptimized(F)]);
  Expect.equals(2, map[getValueNonOptimized(fType)]);
  Expect.isTrue(map.containsKey(getValueNonOptimized(A)));
  Expect.isTrue(map.containsKey(getValueNonOptimized(aType)));
  Expect.isTrue(map.containsKey(getValueNonOptimized(F)));
  Expect.isTrue(map.containsKey(getValueNonOptimized(fType)));
}

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
