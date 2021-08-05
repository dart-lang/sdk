// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-isolate-groups --disable-heap-verification

import 'dart:isolate';

import 'package:expect/expect.dart';

import 'internal.dart';
import 'test_utils.dart';

main(args) async {
  // We don't run this test in our artificial hot reload mode, because it would
  // create too many threads during the reload (one per isolate), which can
  // cause this test or other concurrently executing tests to Crash due to
  // unability of `pthread_create` to create a new thread.
  if (isArtificialReloadMode) return;

  final rp = ReceivePort();
  final int n = 18;
  await spawnInDetachedGroup(fibonacciRecursive, [rp.sendPort, n]);
  Expect.equals(4181, await rp.first);
}
