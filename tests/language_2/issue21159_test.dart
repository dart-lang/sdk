// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class C {
  get call => this;
}

// Recurs outside the try-block to avoid disabling inlining.
foo() {
  dynamic c = new C();
  c();
}

main() {
  bool exceptionCaught = false;
  try {
    foo();
  } on StackOverflowError catch (e) {
    exceptionCaught = true;
  }
  Expect.equals(true, exceptionCaught);
}
