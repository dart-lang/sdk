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

class MyClass {
  final int n;

  const MyClass(this.n);

  int get hashCode => super.hashCode + 1;
}

main() {
  const constInstance = MyClass(1);
  final nonConstInstance = MyClass(1);

  const constSet = {MyClass(1)};
  final nonConstSet = {constInstance};
  final nonConstSet2 = {nonConstInstance};

  // operator== is _not_ overridden, so instances are not equal.
  Expect.notEquals(constInstance, nonConstInstance);

  Expect.isTrue(constSet.contains(getValueNonOptimized(constInstance)));
  Expect.isFalse(constSet.contains(getValueNonOptimized(nonConstInstance)));
  Expect.isTrue(nonConstSet.contains(getValueNonOptimized(constInstance)));
  Expect.isFalse(nonConstSet.contains(getValueNonOptimized(nonConstInstance)));
  Expect.isFalse(nonConstSet2.contains(getValueNonOptimized(constInstance)));
  Expect.isTrue(nonConstSet2.contains(getValueNonOptimized(nonConstInstance)));
}
