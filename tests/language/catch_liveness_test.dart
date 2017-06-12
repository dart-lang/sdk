// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

@AssumeDynamic()
@NoInline()
foo() => 1;

@AssumeDynamic()
@NoInline()
throwException() => throw 'x';

main() {
  var x = 10;
  var e2 = null;
  try {
    var t = foo();
    throwException();
    print(t);
    x = 3;
  } catch (e) {
    Expect.equals(10, x);
    e2 = e;
  }
  Expect.equals(10, x);
  Expect.equals('x', e2);
}
