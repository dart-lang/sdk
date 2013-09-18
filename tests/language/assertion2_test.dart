// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "compiler_annotations.dart";

@DontInline()
foo() {
  () => 42;
  int a;
  assert((a = 2) == 2);
  return a;
}

main() {
  bool isAssertEnabled = false;
  assert(isAssertEnabled = true);
  if (isAssertEnabled) {
    Expect.equals(44, foo() + 42);
  } else {
    Expect.throws(() => foo() + 42, (e) => e is NoSuchMethodError);
  }
}
