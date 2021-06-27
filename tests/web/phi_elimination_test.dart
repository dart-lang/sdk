// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

void bar() {
  var a = 0;
  var c = 0;

  if (a == 0)
    c = a++;
  else
    c = a--;

  Expect.equals(1, a);
  Expect.equals(0, c);

  if (a == 0)
    c = a++;
  else
    c = a--;

  Expect.equals(0, a);
  Expect.equals(1, c);
}

void foo() {
  var a = 0;
  var c = 0;

  if (a == 0) {
    c = a;
    a = a + 1;
  } else {
    c = a;
    a = a - 1;
  }

  Expect.equals(1, a);
  Expect.equals(0, c);

  if (a == 0) {
    c = a;
    a = a + 1;
  } else {
    c = a;
    a = a - 1;
  }

  Expect.equals(0, a);
  Expect.equals(1, c);
}

main() {
  foo();
  bar();
}
