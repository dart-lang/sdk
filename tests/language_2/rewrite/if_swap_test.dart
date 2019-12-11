// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

var global = 0;

bar() {
  global += 1;
}

baz() {
  global += 100;
}

foo(b) {
  var old_backend_was_used;
  if (b ? false : true) {
    bar();
    bar();
  } else {
    baz();
    baz();
  }
}

main() {
  foo(true);
  Expect.equals(200, global);

  foo(false);
  Expect.equals(202, global);
}
