// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests lookup of type literals of user-defined classes in const maps.

import 'package:expect/expect.dart';

class A {}

class C<T> {}

typedef F = T Function<T>();
typedef Cint = C<int>;

const aType = A;
const fType = F;
const cIntType = Cint;

main() {
  final map = const {A: 42, F: 2, 'asdf': 'fdsa', Cint: 'foo'};
  Expect.equals(42, map[getValueNonOptimized(A)]);
  Expect.equals(42, map[getValueNonOptimized(aType)]);
  Expect.equals(2, map[getValueNonOptimized(F)]);
  Expect.equals(2, map[getValueNonOptimized(fType)]);
  Expect.equals('foo', map[getValueNonOptimized(Cint)]);
  Expect.equals('foo', map[getValueNonOptimized(cIntType)]);
  Expect.isTrue(map.containsKey(getValueNonOptimized(A)));
  Expect.isTrue(map.containsKey(getValueNonOptimized(aType)));
  Expect.isTrue(map.containsKey(getValueNonOptimized(F)));
  Expect.isTrue(map.containsKey(getValueNonOptimized(fType)));
  Expect.isTrue(map.containsKey(getValueNonOptimized(Cint)));
  Expect.isTrue(map.containsKey(getValueNonOptimized(cIntType)));
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
