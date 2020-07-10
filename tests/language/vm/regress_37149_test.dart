// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that typedef types used in constants are correctly
// visited in the tree shaker.
// Regression test for https://github.com/dart-lang/sdk/issues/37149.

import 'dart:async' show FutureOr;

typedef ComputeCallback<Q, R> = FutureOr<R> Function(Q message);
typedef _ComputeImpl = Future<R?> Function<Q, R>(
    ComputeCallback<Q, R>? callback, Q? message,
    {String debugLabel});

Future<R?> isolatesCompute<Q, R>(ComputeCallback<Q, R>? callback, Q? message,
    {String? debugLabel}) async {
  return null;
}

const _ComputeImpl compute = isolatesCompute;

main() {
  compute.call(null, null);
}
