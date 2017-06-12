// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Regression test for https://code.google.com/p/dart/issues/detail?id=7994.

void main() {
  Expect.equals(-1, foo());
}

int foo() {
  var list = new List<int>(1024);

  for (int i = 0; i < list.length; i++) list[i] = -i;

  for (int n = list.length; n > 1; n--) {
    for (int i = 0; i < n - 1; i++) {
      if (list[i] > list[i + 1]) {
        return list[i + 1];
      }
    }
  }
}
