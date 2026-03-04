// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// When we get a type `X` that extends a type `T`, we wouldn't be able to find
// the static members of `T`. It is a compile-time error to use an enum
// shorthand for type `X` in these cases.

import 'dart:async';

import '../dot_shorthand_helper.dart';

void extendsInteger<X extends Integer>() {
  X x = .one;
  //    ^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //     ^
  // [cfe] The static getter or field 'one' isn't defined for the type 'X'.
}

void extendsIntegerNullable<X extends Integer?>() {
  X x = .one;
  //    ^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //     ^
  // [cfe] The static getter or field 'one' isn't defined for the type 'X'.
}

void extendsFutureOrInteger<X extends FutureOr<Integer>>() {
  X x = .one;
  //    ^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //     ^
  // [cfe] The static getter or field 'one' isn't defined for the type 'X'.
}
