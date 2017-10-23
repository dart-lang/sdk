// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Deliberately fragment the heap and test that GC peformance does not
// break down.  See https://github.com/dart-lang/sdk/issues/29588
// Normally runs in about 6-7 seconds on an x64 machine, using about 2.5Gbytes
// of memory.
//
// This test is deliberately CPU-light and so it can make a lot of
// progress before the concurrent sweepers are done sweeping the heap.
// In that time there is no freelist and so the issue does not arise.
// VMOptions=--no-concurrent-sweep
// VMOptions=--use-compactor

main() {
  final List<List> arrays = [];
  // Fill up heap with alternate large-small items.
  for (int i = 0; i < 500000; i++) {
    arrays.add(new List(260));
    arrays.add(new List(1));
  }
  // Clear the large items so that the heap is full of 260-word gaps.
  for (int i = 0; i < arrays.length; i += 2) {
    arrays[i] = null;
  }
  // Allocate a lot of 300-word objects that don't fit in the gaps.
  for (int i = 0; i < 600000; i++) {
    arrays.add(new List(300));
  }
}
