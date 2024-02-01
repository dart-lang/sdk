// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension EInt on (int,) {
  dynamic call(dynamic x) => x;
}

extension EIntIntCallInt on (int, int, {dynamic Function(dynamic) call}) {
  dynamic call(dynamic x) => x;
}

test<X1 extends (int,), X2 extends (int, {dynamic Function(dynamic) call}), X3 extends (int, int, {dynamic Function(dynamic) call}), X4 extends (String,)>(
    (int,) r1,
    (int, {dynamic Function(dynamic) call}) r2,
    (int, int, {dynamic Function(dynamic) call}) r3,
    (String,) r4,
    X1 x1,
    X2 x2,
    X3 x3,
    X4 x4,
    X1? x1n,
    X2? x2n,
    X3? x3n,
    X4? x4n) {
  r1(0); // Ok.
  r2(0); // Error.
  r3(0); // Error.
  r4(0); // Error.
  r1.call(0); // Ok.
  r2.call(0); // Ok.
  r3.call(0); // Ok.
  r4.call(0); // Error.

  x1(0); // Ok.
  x2(0); // Error.
  x3(0); // Error.
  x4(0); // Error.
  x1n(0); // Error.
  x2n(0); // Error.
  x3n(0); // Error.
  x4n(0); // Error.

  x1.call(0); // Ok.
  x2.call(0); // Ok.
  x3.call(0); // Ok.
  x4.call(0); // Error.
  x1n.call(0); // Error.
  x2n.call(0); // Error.
  x3n.call(0); // Error.
  x4n.call(0); // Error.
}
