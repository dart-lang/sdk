// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A {
  int? get foo;
  int get bar;
  int? get baz;
  num get boz;
  bool get qux;
  String get quux;
  int get foobar;
}

test(x, y, z) {
  var qux;
  var quux;
  if (x case A(:var foo!, :var bar, :var baz?, :var boz as double,
      :(var foobar))) {
    return 0;
  } else if (x case (:var foo!, :var bar, :var baz?, var boz as double,
      :(var foobar))) {
    return 1;
  } else if (x case A(: [1, 2])) { // Error
    return 2;
  } else if (x case (: [1, 2])) { // Error
    return 3;
  }

  A(:qux, :quux) = y;
  (qux, :quux) = z;
}