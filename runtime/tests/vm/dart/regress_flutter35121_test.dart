// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is a regression test for
// https://github.com/flutter/flutter/issues/35121

class A {
  static List<int> values = const [1, 2, 3];
  static int get length => values.length;
}

main() {
  print(A.length);
}
