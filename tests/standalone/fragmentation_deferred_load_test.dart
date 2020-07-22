// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--use_compactor

// Each loading unit creates more image pages in the heap, which unfortunately
// cannot be aligned stronger than virtual memory page alignment, so the
// compactor must detect references to these image pages separately. Before
// these loading units were implemented, the compactor could assume a small
// upper bound on the number of image pages.

import "package:expect/expect.dart";
import "fragmentation_deferred_load_lib1.dart" deferred as lib1;
import "fragmentation_deferred_load_lib2.dart" deferred as lib2;
import "fragmentation_deferred_load_lib3.dart" deferred as lib3;

main() async {
  await lib1.loadLibrary();
  Expect.equals("one!", lib1.foo());
  await lib2.loadLibrary();
  Expect.equals("two!", lib2.foo());
  await lib3.loadLibrary();
  Expect.equals("three!", lib3.foo());

  final List<List?> arrays = [];
  // Fill up heap with alternate large-small items.
  for (int i = 0; i < 500000; i++) {
    arrays.add(new List<dynamic>.filled(260, null));
    arrays.add(new List<dynamic>.filled(1, null));
  }
  // Clear the large items so that the heap is full of 260-word gaps.
  for (int i = 0; i < arrays.length; i += 2) {
    arrays[i] = null;
  }
  // Allocate a lot of 300-word objects that don't fit in the gaps.
  for (int i = 0; i < 600000; i++) {
    arrays.add(new List<dynamic>.filled(300, null));
  }
}
