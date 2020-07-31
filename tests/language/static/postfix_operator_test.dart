// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

int a = 0;
int b = 0;

withTryFinally() {
  bool inIt = false;
  // Do a try/finally to potentially force a non-optimizing compiler.
  try {
    if (a++ == 0) {
      inIt = true;
    }
  } finally {}
  Expect.isTrue(inIt);
}

withoutTryFinally() {
  bool inIt = false;
  if (b++ == 0) {
    inIt = true;
  }
  Expect.isTrue(inIt);
}

main() {
  withTryFinally();
  withoutTryFinally();
}
