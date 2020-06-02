// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--no_concurrent_mark --no_concurrent_sweep
// VMOptions=--no_concurrent_mark --concurrent_sweep
// VMOptions=--no_concurrent_mark --use_compactor
// VMOptions=--no_concurrent_mark --use_compactor --force_evacuation
// VMOptions=--concurrent_mark --no_concurrent_sweep
// VMOptions=--concurrent_mark --concurrent_sweep
// VMOptions=--concurrent_mark --use_compactor
// VMOptions=--concurrent_mark --use_compactor --force_evacuation

import 'dart:typed_data';

main() {
  final List<List?> arrays = [];
  // Fill up heap with alternate large-small items.
  for (int i = 0; i < 500000; i++) {
    arrays.add(new Uint32List(260));
    arrays.add(new Uint32List(1));
  }
  // Clear the large items so the heap has large gaps.
  for (int i = 0; i < arrays.length; i += 2) {
    arrays[i] = null;
  }
  // Allocate a lot of large items which don't fit in the gaps created above.
  for (int i = 0; i < 600000; i++) {
    arrays.add(new Uint32List(300));
  }
}
