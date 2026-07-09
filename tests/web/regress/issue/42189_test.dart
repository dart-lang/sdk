// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// dart2jsOptions=-O0

// Regression test for issue 42891. The root cause was a malformed SSA due to
// generating a dynamic entry point argument test for an elided parameter
// directly on the HLocalValue , which should only be an operand to HLocalGet
// and HLocalSet.

import "package:expect/expect.dart";

class CCC {
  void foo([num x = 123]) {
    try {
      Expect.equals(123, x);
      x = 0;
    } finally {
      Expect.equals(0, x);
    }
  }

  void bar([num x = 456]) {
    try {
      Expect.equals(123, x);
      x = 0;
    } finally {
      Expect.equals(0, x);
    }
  }
}

void main() {
  CCC().foo();
  CCC().bar(123);
}
