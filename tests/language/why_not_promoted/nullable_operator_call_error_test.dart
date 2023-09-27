// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test contains a test case for each condition that can lead to the front
// end's `NullableOperatorCallError` error, for which we wish to report "why not
// promoted" context information.

class C1 {
  int? bad;
  //   ^^^
  // [context 1] 'bad' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 3] 'bad' refers to a public field so it couldn't be promoted.
}

userDefinableBinaryOpLhs(C1 c) {
  if (c.bad == null) return;
  c.bad + 1;
  //    ^
  // [analyzer 1] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [cfe 3] Operator '+' cannot be called on 'int?' because it is potentially null.
}

class C2 {
  int? bad;
  //   ^^^
  // [context 2] 'bad' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 4] 'bad' refers to a public field so it couldn't be promoted.
}

userDefinableUnaryOp(C2 c) {
  if (c.bad == null) return;
  -c.bad;
//^
// [analyzer 2] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
// [cfe 4] Operator 'unary-' cannot be called on 'int?' because it is potentially null.
}
