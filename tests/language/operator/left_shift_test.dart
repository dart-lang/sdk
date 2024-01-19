// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  for (int i = 0; i < 80; i++) {
    var a = -1 << i;
    // web shifts produce a 32-bit unsigned result. Make it signed.
    if (webNumbers) a = a.toSigned(32);
    var b = -1;
    Expect.equals(1 << i, a ~/ b);
  }
}
