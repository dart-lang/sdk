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

class MyClass {
  final int n;

  const MyClass(this.n);

  int get hashCode => super.hashCode + 1;
}

main() {
  const constInstance = MyClass(1);
  final nonConstInstance = MyClass(1);

  const constMap = {MyClass(1): 11};
  final nonConstMap = {constInstance: 11};
  final nonConstMap2 = {nonConstInstance: 11};

  // operator== is _not_ overridden, so instances are not equal.
  Expect.notEquals(constInstance, nonConstInstance);

  Expect.isTrue(constMap.containsKey(getValueNonOptimized(constInstance)));
  Expect.isFalse(constMap.containsKey(getValueNonOptimized(nonConstInstance)));
  Expect.isTrue(nonConstMap.containsKey(getValueNonOptimized(constInstance)));
  Expect.isFalse(
      nonConstMap.containsKey(getValueNonOptimized(nonConstInstance)));
  Expect.isFalse(nonConstMap2.containsKey(getValueNonOptimized(constInstance)));
  Expect.isTrue(
      nonConstMap2.containsKey(getValueNonOptimized(nonConstInstance)));

  Expect.equals(11, constMap[getValueNonOptimized(constInstance)]);
  Expect.isNull(constMap[getValueNonOptimized(nonConstInstance)]);
  Expect.equals(11, nonConstMap[getValueNonOptimized(constInstance)]);
  Expect.isNull(nonConstMap[getValueNonOptimized(nonConstInstance)]);
  Expect.isNull(nonConstMap2[getValueNonOptimized(constInstance)]);
  Expect.equals(11, nonConstMap2[getValueNonOptimized(nonConstInstance)]);
}
