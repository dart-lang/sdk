// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test for a bug in dart2js where the update of a field in a try
// block would not be seen by the finally block. See dartbug.com/5517.

class A {
  int i;
  A() : i = 42;

  foo() {
    bool executedFinally = false;
    if (i == 42) {
      try {
        i = 12;
      } finally {
        Expect.equals(12, i);
        executedFinally = true;
      }
    }
    Expect.isTrue(executedFinally);
  }
}

main() {
  new A().foo();
}
