// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

@pragma('dart2js:assumeDynamic')
@pragma('dart2js:noInline')
foo() => 1;

@pragma('dart2js:assumeDynamic')
@pragma('dart2js:noInline')
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
