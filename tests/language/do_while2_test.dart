// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

var a = 42;

foo1() {
  var i = 0;
  var saved;
  do {
    saved = i;
    i = a;
  } while (i == saved);
  Expect.equals(0, saved);
  Expect.equals(42, i);
}

foo2() {
  var i = 0;
  var saved;
  do {
    saved = i;
    i = a;
  } while (i != saved);
  Expect.equals(42, saved);
  Expect.equals(42, i);
}

foo3() {
  var i = 0;
  var saved;
  do {
    saved = i;
    i = a;
    if (i == saved) continue;
  } while (i != saved);
  Expect.equals(42, saved);
  Expect.equals(42, i);
}

main() {
  foo1();
  foo2();
  foo3();
}
