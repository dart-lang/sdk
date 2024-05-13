// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--profiler --profile-vm=true
// VMOptions=--profiler --profile-vm=false

import "dart:typed_data";

main() {
  Uint8List a = new Uint8List(2 << 20);
  Uint8List b = new Uint8List(2 << 20);

  for (int i = 0; i < a.length; i++) {
    a[i] = i;
  }

  for (int i = 0; i < 1000; i++) {
    b.setRange(0, a.length, a); // Implemented via memmove.
    a.setRange(0, b.length, b); // Implemented via memmove.
  }

  for (int i = 0; i < a.length; i++) {
    if (a[i] != (i & 0xFF)) throw "A";
  }
  for (int i = 0; i < a.length; i++) {
    if (b[i] != (i & 0xFF)) throw "A";
  }
}
