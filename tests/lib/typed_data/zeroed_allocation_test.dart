// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';
import 'package:expect/expect.dart';

final KB = 1024;

final interestingSizes = <int>[
  4 * KB, // VirtualMemory::PageSize()
  64 * KB, // Heap::kAllocatablePageSize
  256 * KB, // Heap::kNewAllocatableSize
  512 * KB, // PageSpace::kPageSize
];

main() {
  for (var base in interestingSizes) {
    for (var delta = -32; delta <= 32; delta++) {
      final size = base + delta;
      final array = new Uint8List(size);
      for (var i = 0; i < size; i++) {
        Expect.equals(0, array[i]);
      }
    }
  }
}
