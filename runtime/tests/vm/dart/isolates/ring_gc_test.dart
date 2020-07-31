// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-isolate-groups --disable-heap-verification

import 'dart:async';
import 'dart:math' as math;
import 'dart:isolate';

import 'package:expect/expect.dart';

import 'test_utils.dart';

class Worker extends RingElement {
  final int id;
  Worker(this.id);

  Future run(SendPort next, StreamIterator prev) async {
    final Tree tree = buildTree(id % 10);

    // Send to next in ring.
    next.send(tree);
    // Receive from previous in ring.
    await prev.moveNext();
    final prevTree = prev.current as Tree;

    // Return to main
    return prevTree;
  }
}

main(args) async {
  final int numIsolates = (isDebugMode || isSimulator) ? 100 : 1000;

  // Spawn ring of 1k isolates.
  final ring = await Ring.create(numIsolates);

  // Let each node produce a tree, send it to it's neighbour and let it return
  // the one it received.
  final results = await ring.run((int id) => Worker(id));
  Expect.equals(numIsolates, results.length);

  // Validate the result.
  for (int i = 0; i < numIsolates; ++i) {
    final Tree tree = results[i];
    final senderId = (numIsolates + i - 1) % numIsolates;
    final expectedCount = math.pow(2, senderId % 10) - 1;
    Expect.equals(expectedCount, tree.sum);
  }

  // Close the ring.
  await ring.close();
}
