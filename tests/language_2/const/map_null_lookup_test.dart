// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests lookup of null in const maps.

// @dart = 2.9

import 'package:expect/expect.dart';

main() {
  final map1 = const {1: 42, null: 2, 'asdf': 'fdsa'};
  Expect.equals(2, map1[getValueNonOptimized(null)]);
  Expect.isTrue(map1.containsKey(null));
  final map2 = const {1: 42, 2: 2, 'asdf': 'fdsa'};
  Expect.equals(null, map2[getValueNonOptimized(null)]);
  Expect.isFalse(map2.containsKey(null));
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
