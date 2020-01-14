// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

var global = 0;

effect() {
  global = 1;
}

baz(b) {
  return b;
}

foo(b) {
  if (b) {
    // do nothing
  } else {
    effect();
  }
  return baz(b);
}

foo2(b) {
  if (b) {
    // do nothing (but implicit return may get inlined up here)
  } else {
    effect();
  }
}

main() {
  global = 0;
  Expect.equals(true, foo(true));
  Expect.equals(0, global);

  global = 0;
  Expect.equals(false, foo(false));
  Expect.equals(1, global);

  global = 0;
  foo2(true);
  Expect.equals(0, global);

  global = 0;
  foo2(false);
  Expect.equals(1, global);
}
