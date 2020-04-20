// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

var global = 0;

bar() {
  global += 1;
}

baz() {
  global += 100;
}

foo(x, y, z) {
  if ((x ? false : true) ? y : z) {
    bar();
    bar();
  } else {
    baz();
    baz();
  }
}

foo2(x, y, z) {
  return (x ? false : true) ? y : z;
}

foo3(x, y, z) {
  if (x ? (z ? false : true) : (y ? false : true)) {
    baz();
    baz();
  } else {
    bar();
    bar();
  }
}

main() {
  foo(true, true, true);
  Expect.equals(2, global);

  foo(true, true, false);
  Expect.equals(202, global);

  foo(true, false, true);
  Expect.equals(204, global);

  foo(true, false, false);
  Expect.equals(404, global);

  foo(false, true, true);
  Expect.equals(406, global);

  foo(false, true, false);
  Expect.equals(408, global);

  foo(false, false, true);
  Expect.equals(608, global);

  foo(false, false, false);
  Expect.equals(808, global);

  Expect.equals(true, foo2(true, true, true));
  Expect.equals(false, foo2(true, true, false));
  Expect.equals(true, foo2(true, false, true));
  Expect.equals(false, foo2(true, false, false));
  Expect.equals(true, foo2(false, true, true));
  Expect.equals(true, foo2(false, true, false));
  Expect.equals(false, foo2(false, false, true));
  Expect.equals(false, foo2(false, false, false));

  global = 0;
  foo3(true, true, true);
  Expect.equals(2, global);

  foo3(true, true, false);
  Expect.equals(202, global);

  foo3(true, false, true);
  Expect.equals(204, global);

  foo3(true, false, false);
  Expect.equals(404, global);

  foo3(false, true, true);
  Expect.equals(406, global);

  foo3(false, true, false);
  Expect.equals(408, global);

  foo3(false, false, true);
  Expect.equals(608, global);

  foo3(false, false, false);
  Expect.equals(808, global);
}
