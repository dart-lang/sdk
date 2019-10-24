// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--deterministic

// Found by DartFuzzing: would fail during deopt:
// https://github.com/dart-lang/sdk/issues/38741

import 'package:expect/expect.dart';

@pragma('vm:prefer-inline')
bool foo(int x) => x < 10;

@pragma('vm:never-inline')
bool bar(bool f) => f && foo(1);

void main() {
  try {
    foo(null); // seed feedback for x < 10 with null receiver cid
  } catch (e) {}
  // Now when foo will be inlined into bar we will know that x is Smi,
  // this hower disagrees with type feedback (which currently is monomorphic and
  // expects null receiver for x < 10).
  for (var i = 0; i < 10000; i++) Expect.isFalse(bar(false));
  Expect.isTrue(bar(true));
}
