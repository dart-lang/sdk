// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

var global = 0;

bar() {
  global = 1;
}

baz() {
  global = 2;
}

return_const(b) {
  if (b) {
    bar();
    return 1;
  } else {
    baz();
    return 1;
  }
}

return_var(b, x) {
  if (b) {
    bar();
    return x;
  } else {
    baz();
    return x;
  }
}

main() {
  return_const(true);
  Expect.equals(1, global);
  return_const(false);
  Expect.equals(2, global);

  Expect.equals(4, return_var(true, 4));
  Expect.equals(1, global);
  Expect.equals(5, return_var(false, 5));
  Expect.equals(2, global);
}
