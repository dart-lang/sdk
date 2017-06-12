// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// This program tripped dart2js.
main() {
  int foo;
  for (var i = 0; i < 10; foo = i, i++) {
    if (i > 0) {
      Expect.equals(i - 1, foo);
    }
  }
}
