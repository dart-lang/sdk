// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test optimization of byte array views on external data.

// Library tag to be able to run in html test framework.
library ByteArrayViewOptimizedTest;

import "package:expect/expect.dart";
import "dart:typed_data";

li16(v) => v[0];

main() {
  var a = new Uint8List(2);
  a[0] = a[1] = 0xff;
  var b = new Int16List.view(a.buffer);
  Expect.equals(-1, li16(b));
  for (var i = 0; i < 10000; i++) li16(b);
  Expect.equals(-1, li16(b));
}
