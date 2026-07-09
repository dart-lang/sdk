// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:typed_data";

Uint8List var9 = Uint8List(0);
bool var31 = false;

foo0() {
  int loc0 = 0;
  do {
    try {
      throw "catch is reachable";
    } catch (exception, stackTrace) {
      print(var9[var31 ? loc0 : -88]);
    }
  } while (++loc0 < 23);
}

main() {
  try {
    foo0();
  } catch (_) {}
}
