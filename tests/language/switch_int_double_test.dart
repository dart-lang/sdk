// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that double literals with no fractional part is not treated as having
// static type int.

import "package:expect/expect.dart";

void main() {
  Expect.equals(100, test(1.0));
  Expect.equals(75, test(0.75));
  Expect.equals(null, test(0.5));
}

int test(num ratio) {
  switch (ratio) {
    case 0.75:
      return 75;
    case 1.0:
      return 100;
    case 2:       /// 01: compile-time error
      return 200; /// 01: continued
    case 'foo':   /// 02: compile-time error
      return 400; /// 02: continued
  }
}