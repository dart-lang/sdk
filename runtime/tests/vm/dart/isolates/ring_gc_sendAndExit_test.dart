// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-isolate-groups --disable-heap-verification

import 'dart:math' as math;

import 'package:expect/expect.dart';

import 'ring_gc_test.dart' show Worker;
import 'test_utils.dart';

main(args) async {
  final int numIsolates = (isDebugMode || isSimulator) ? 100 : 5000;

  // Spawn ring of 1k isolates.
  final ring = await Ring.create(numIsolates);

  // Let each node produce a tree, send it to it's neighbour and let it return
  // the one it received (via sendAndExit).
  final results = await ring.runAndClose((int id) => Worker(id));
  Expect.equals(numIsolates, results.length);

  // Validate the result.
  for (int i = 0; i < numIsolates; ++i) {
    final Tree tree = results[i];
    final senderId = (numIsolates + i - 1) % numIsolates;
    final expectedCount = math.pow(2, senderId % 10) - 1;
    Expect.equals(expectedCount, tree.sum);
  }
}
