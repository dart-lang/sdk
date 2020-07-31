// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

dynamic a = 42;

inlineMe() {
  // Add control flow to confuse the compiler.
  if (a is int) {
    print('a is int');
  }
  return a[0];
}

main() {
  a = [42];
  // Make [main] recursive to force a bailout version.
  if (false) main();
  int i = 0;
  for (i = inlineMe(); i < 42; i++);
  Expect.equals(42, i);
}
