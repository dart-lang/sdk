// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type E1(Object it) {} // Potentially nullable.
extension type E2(Object it) implements Object {} // Non-nullable.
extension type E3(Object it) implements E1 {} // Potentially nullable.
extension type E4(Object it) implements E2 {} // Non-nullable.
extension type E5<X>(X it) {} // Potentially nullable.
extension type E6<X extends Object>(X it) implements Object {} // Non-nullable.
extension type E7(num it) implements num {} // Non-nullable.

test1(E1 e1, E2 e2, E3 e3, E4 e4, E5 e5, E6 e6, E7 e7) {
  Object v1 = e1; // Error.
  e1 = null; // Error.

  Object v2 = e2; // Ok.
  e2 = null; // Error.

  Object v3 = e3; // Error.
  e3 = null; // Error.

  Object v4 = e4; // Ok.
  e4 = null; // Error.

  Object v5 = e5; // Error.
  e5 = null; // Error.

  Object v6 = e6; // Ok.
  e6 = null; // Error.

  Object v7 = e7; // Ok.
  e7 = null; // Error.
}

test2<X1 extends E1, X2 extends E2, X3 extends E3, X4 extends E4, X5 extends E5, X6 extends E6, X7 extends E7>(
    X1 x1, X2 x2, X3 x3, X4 x4, X5 x5, X6 x6, X7 x7) {
  Object v1 = x1; // Error.
  x1 = null; // Error.

  Object v2 = x2; // Ok.
  x2 = null; // Error.

  Object v3 = x3; // Error.
  x3 = null; // Error.

  Object v4 = x4; // Ok.
  x4 = null; // Error.

  Object v5 = x5; // Error.
  x5 = null; // Error.

  Object v6 = x6; // Ok.
  x6 = null; // Error.

  Object v7 = x7; // Ok.
  x7 = null; // Error.
}

test3(E1 e1, E2 e2, E3 e3, E4 e4, E5 e5, E6 e6, E7 e7, String s, bool b) {
  var v11 = b ? e1 : s;
  Object v12 = v11; // Error.
  v11 = null; // Ok.

  var v21 = b ? e2 : s;
  Object v22 = v21; // Ok.
  v21 = null; // Error.

  var v31 = b ? e3 : s;
  Object v32 = v31; // Error.
  v31 = null; // Ok.

  var v41 = b ? e4 : s;
  Object v42 = v41; // Ok.
  v41 = null; // Error.

  var v51 = b ? e5 : s;
  Object v52 = v51; // Error.
  v51 = null; // Ok.

  var v61 = b ? e6 : s;
  Object v62 = v61; // Ok.
  v61 = null; // Error.

  var v71 = b ? e7 : s;
  Object v72 = v71; // Ok.
  v71 = null; // Error.
}
