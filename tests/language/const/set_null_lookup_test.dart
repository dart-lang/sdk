// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests lookup of null in const maps.

import 'package:expect/expect.dart';

main() {
  final set1 = const {null, 1, 'asdf'};
  Expect.isTrue(set1.contains(getValueNonOptimized(null)));
  Expect.equals(null, set1.lookup(null));
  final set2 = const {42, 1, 'asdf'};
  Expect.isFalse(set2.contains(getValueNonOptimized(null)));
  Expect.equals(null, set2.lookup(null));
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
