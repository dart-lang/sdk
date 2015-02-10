// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


abstract class X {
  int f() => 42;
}

abstract class Y {
  int x;
  int f();
}

abstract class Predicate { //LINT
  test();
}

abstract class Z extends X {
  test();
}

abstract class ZZ extends Predicate {
}