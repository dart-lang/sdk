// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/* `return exp;` where `exp` has static type `S` is an error if the future
 * value type of the function is neither `void` nor `dynamic`,
 * and `flatten(S)` is `void` or `void*`.
 */

Future<void> v = Future.value("Hello");

FutureOr<Null> test1() async {
  return v;
  //     ^
  // [analyzer] COMPILE_TIME_ERROR.RETURN_OF_INVALID_TYPE
  // [cfe] A value of type 'Future<void>' can't be returned from an async function with return type 'FutureOr<Null>'.
}

// Inferred return type of function literal is `Future<Null>`.
FutureOr<Null> Function() test2 = () async {
  return v;
  //     ^
  // [analyzer] COMPILE_TIME_ERROR.RETURN_OF_INVALID_TYPE_FROM_CLOSURE
  // [cfe] A value of type 'Future<void>' can't be returned from an async function with return type 'Future<Null>'.
};

void main() {
  test1();
  test2();
}
