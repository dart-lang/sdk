// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  dynamic a = 'foo';
  for (int i = 0; i < 10; i++) {
    if (i == 0) {
      Expect.isTrue(identical(a, 'foo'));
    } else {
      Expect.isTrue(a == 2);
    }
    a = 2;
  }
}
