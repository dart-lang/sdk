// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the compiler's load elimination phase does not re-use the
// value that was stored in a typed array.

import "dart:typed_data";

main() {
  var list = new Int8List(1);
  list[0] = 300;
  if (list[0] != 44) {
    throw 'Test failed';
  }

  var a = list[0];
  list[0] = 0;
  if (list[0] != 0) {
    throw 'Test failed';
  }
}
