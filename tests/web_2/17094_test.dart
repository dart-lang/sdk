// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import "package:expect/expect.dart";

//  Interpolation effect analysis test.

get never => new DateTime.now().millisecondsSinceEpoch == 0;

class A {
  int a = 0;
  toString() {
    ++a;
    return 'A';
  }
}

// Many interpolations to make function too big to inline.
// Summary for [fmt] must include effects from toString().
fmt(x) => '$x$x$x$x$x$x$x$x$x$x$x$x$x$x$x$x$x$x$x$x$x$x$x$x$x$x$x$x$x$x';

test(a) {
  if (a == null) return;
  if (never) a.a += 1;
  var b = a.a; // field load
  var c = fmt(a); // field modified through implicit call to toString()
  var d = a.a; // field re-load
  Expect.equals('A 0 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA 30', '$a $b $c $d');

  // Extra use of [fmt] to prevent inlining on basis of single reference.
  Expect.equals('', fmt(''));
}

main() {
  test(null);
  test(new A());
}
