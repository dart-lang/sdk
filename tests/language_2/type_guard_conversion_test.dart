// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

foo() => 'bar';

main() {
  var a = foo();
  var b = 'c';
  do {
    b = a[2];
  } while (b != 'r');

  if (a is Comparable) {
    a += a;
  }
  Expect.equals('barbar', a);
}
