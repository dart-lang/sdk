// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--reify-generic-functions

import "package:expect/expect.dart";

T foo<T>(T i) => i;

void main() {
  Expect.equals(42, foo<int>(42));

  var bar = foo;
  Expect.equals(42, bar<int>(42));

  // Generic function types are not allowed as type arguments.
  List<T Function<T>(T)> typedList = <T Function<T>(T)>[foo];
  //   ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.GENERIC_FUNCTION_TYPE_CANNOT_BE_TYPE_ARGUMENT
  //                     ^
  // [cfe] A generic function type can't be used as a type argument.

  // Type inference must also give an error.
  var inferredList = [foo];
  //  ^
  // [cfe] Generic function type 'T Function<T>(T)' inferred as a type argument.
  //                 ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.COULD_NOT_INFER

  // No error if illegal type cannot be inferred.
  var dynamicList = <dynamic>[foo];
  Expect.equals(42, (dynamicList[0] as T Function<T>(T))<int>(42));
}
