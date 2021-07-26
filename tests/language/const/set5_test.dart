// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests lookup of type literals of user-defined classes in const sets.

import 'package:expect/expect.dart';

class A {}

class C<T> {}

typedef F = T Function<T>();
typedef Cint = C<int>;

const aType = A;
const fType = F;
const cIntType = Cint;

main() {
  final set1 = const {A, 1, 'asdf', F, Cint};
  Expect.isTrue(set1.contains(getValueNonOptimized(A)));
  Expect.isTrue(set1.contains(getValueNonOptimized(aType)));
  Expect.isTrue(set1.contains(getValueNonOptimized(F)));
  Expect.isTrue(set1.contains(getValueNonOptimized(fType)));
  Expect.isTrue(set1.contains(getValueNonOptimized(Cint)));
  Expect.isTrue(set1.contains(getValueNonOptimized(cIntType)));
  Expect.equals(A, set1.lookup(getValueNonOptimized(A)));
  Expect.equals(A, set1.lookup(getValueNonOptimized(aType)));
  Expect.equals(F, set1.lookup(getValueNonOptimized(F)));
  Expect.equals(F, set1.lookup(getValueNonOptimized(fType)));
  Expect.equals(Cint, set1.lookup(getValueNonOptimized(Cint)));
  Expect.equals(Cint, set1.lookup(getValueNonOptimized(cIntType)));
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
