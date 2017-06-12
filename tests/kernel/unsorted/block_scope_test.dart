// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests of block scoping.

import 'package:expect/expect.dart';

bool oracle() => true;

test0() {
  var x = 'outer', y = x;
  Expect.isTrue(x == 'outer');
  Expect.isTrue(y == 'outer');
  {
    var x = 'inner';
    Expect.isTrue(x == 'inner');
    Expect.isTrue(y == 'outer');
  }
  Expect.isTrue(x == 'outer');
  Expect.isTrue(y == 'outer');

  if (oracle()) {
    var y = 'inner';
    Expect.isTrue(x == 'outer');
    Expect.isTrue(y == 'inner');
  } else {
    Expect.isTrue(false);
  }
  Expect.isTrue(x == 'outer');
  Expect.isTrue(y == 'outer');
}

var x = 'toplevel';

test1() {
  var y = 'outer';
  Expect.isTrue(x == 'toplevel');
  Expect.isTrue(y == 'outer');
  {
    var x = 'inner';
    Expect.isTrue(x == 'inner');
    Expect.isTrue(y == 'outer');
  }
  Expect.isTrue(x == 'toplevel');
  Expect.isTrue(y == 'outer');

  if (oracle()) {
    var y = 'inner';
    Expect.isTrue(x == 'toplevel');
    Expect.isTrue(y == 'inner');
  } else {
    Expect.isTrue(false);
  }
  Expect.isTrue(x == 'toplevel');
  Expect.isTrue(y == 'outer');
}

main() {
  test0();
  test1();
}
