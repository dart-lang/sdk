// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:expect/expect.dart";

foo(x) {}

main() {
  for (var i = 0; i < 1; i++) {
    foo(i + 1);
    Expect.equals(0, i);
  }
}
