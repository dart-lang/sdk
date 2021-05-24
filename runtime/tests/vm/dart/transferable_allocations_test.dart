// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that Transferable (external old space) objects are promptly gc'ed.
// The test will run out of ia32 3GB heap allocation if objects are not gc'ed.

// VMOptions=--old_gen_heap_size=32

import 'dart:isolate';
import 'dart:typed_data';

void main() {
  final data = Uint8List.view(new Uint8List(5 * 1024 * 1024).buffer);
  for (int i = 0; i < 1000; i++) {
    TransferableTypedData.fromList(<Uint8List>[data]).materialize();
  }
}
