// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedObjects=ffi_test_functions
// VMOptions=--enable-isolate-groups --disable-heap-verification --disable-thread-pool-limit

import 'dart:async';
import 'dart:math' as math;

import 'package:expect/expect.dart';

import 'test_utils.dart';

// This should be larger than max-new-space-size/tlab-size.
const int threadCount = 1000;
const int treeHeight = 10;
final expectedSum = math.pow(2, treeHeight) - 1;

class Worker extends RingElement {
  final int id;
  Worker(this.id);

  Future run(dynamic _, dynamic _2) async {
    return buildTree(treeHeight).sum;
  }
}

main(args) async {
  // This test tests a custom embedder which installs it's own message handler
  // and therefore does not use our thread pool implementation.
  // The test passes `--disable-thread-pool-limit` to similate an embedder which
  // can use arbitrarily number of threads.
  //
  // The VM is responsible for ensuring at most N number of mutator threads can
  // be actively executing Dart code (if not, too many threads would be fighting
  // to obtain TLABs and performance would be terrible).

  final ring = await Ring.create(threadCount);

  // Let each worker do a lot of allocations: If the VM doesn't limit the number
  // of concurrent mutators, it would cause the threads to fight over TLABs and
  // this test would timeout.
  final results = await ring.run((int id) => Worker(id));

  Expect.equals(threadCount, results.length);
  for (int i = 0; i < threadCount; ++i) {
    final int sum = results[i];
    Expect.equals(expectedSum, sum);
  }

  await ring.close();
}
