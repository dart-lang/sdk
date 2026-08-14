// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Regression test for https://github.com/dart-lang/sdk/issues/64035.
//
// Closure allocation initializes the closure's hash field to Smi 0, not
// null, and _Closure.get:hashCode relies on that to detect a not yet
// computed hash code. Load forwarding used to replace a load of the hash
// field of a freshly allocated closure with null, making an inlined
// hashCode return null out of a non-nullable int getter.
//
// VMOptions=--optimization-counter-threshold=100 --deterministic

import 'package:expect/expect.dart';

@pragma('vm:never-inline')
int hashOf() {
  final c = () {};
  return c.hashCode;
}

void main() {
  for (var i = 0; i < 10000; i++) {
    Expect.type<int>(hashOf());
  }
}
