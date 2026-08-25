// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/64112.
//
// When a bool local is combined with a non-short-circuiting binary operator
// (|, &, ^) whose other operand contains an await inside a try block,
// dart2wasm was emitting invalid wasm where a bool (i32) was left on the stack
// across an async suspension.

import 'package:expect/expect.dart';

Future<bool> applyState(bool val) async => val;

bool finallyRan = false;

Future<bool> testTryFinallyOr(bool initial, bool value) async {
  var changed = initial;
  finallyRan = false;
  try {
    changed |= await applyState(value);
    return changed;
  } finally {
    finallyRan = true;
  }
}

void main() async {
  Expect.isTrue(await testTryFinallyOr(false, true));
  Expect.isTrue(finallyRan);
  Expect.isFalse(await testTryFinallyOr(false, false));
  Expect.isTrue(finallyRan);
  Expect.isTrue(await testTryFinallyOr(true, false));
  Expect.isTrue(finallyRan);
}
