// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// VMOptions=--disable_heap_verification --no_check_function_fingerprints

import 'dart:isolate';

import 'package:expect/expect.dart';

import 'test_utils.dart';

main(args) async {
  // We don't run this test in our artificial hot reload mode, because it would
  // create too many threads during the reload (one per isolate), which can
  // cause this test or other concurrently executing tests to Crash due to
  // unability of `pthread_create` to create a new thread.
  if (isArtificialReloadMode) return;

  final rp = ReceivePort();
  final int n = 18;
  await Isolate.spawn(fibonacciRecursive, [rp.sendPort, n]);
  Expect.equals(4181, await rp.first);
}
