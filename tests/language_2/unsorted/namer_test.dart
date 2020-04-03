// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Regression test for a bug in dart2js where global names could
// collide.

var i = 'top level';

var i0 = 'top level zero';

var i00 = 'top level zero zero';

var i2 = 'top level too';

class A {
  static var i = 'A';
}

var j = 'top level';

var j0 = 'top level zero';

var j00 = 'top level zero zero';

var j2 = 'top level too';

class B {
  static var j = 'B';
}

var k = 'top level';

var k0 = 'top level zero';

var k00 = 'top level zero zero';

var k2 = 'top level too';

class C {
  static var k = 'C';
}

main() {
  // Order matters. This sequence triggered the bug.
  Expect.equals('top level', i);
  Expect.equals('A', A.i);
  Expect.equals('top level too', i2);
  Expect.equals('top level zero zero', i00);
  Expect.equals('top level zero', i0);

  Expect.equals('top level zero zero', j00);
  Expect.equals('top level', j);
  Expect.equals('top level too', j2);
  Expect.equals('top level zero', j0);
  Expect.equals('B', B.j);

  Expect.equals('top level too', k2);
  Expect.equals('top level zero', k0);
  Expect.equals('top level', k);
  Expect.equals('C', C.k);
  Expect.equals('top level zero zero', k00);
}
