// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/* `return exp;` where `exp` has static type `S` is an error if the future
 * value type of the function is neither `void` nor `dynamic`,
 * and `flatten(S)` is `void` or `void*`.
 */

Future<void> v = Future.value(null);

Future<Object?> test1() async {
  return v;
  //     ^
  // [analyzer] unspecified
  // [cfe] A value of type 'Future<void>' can't be returned from an async function with return type 'Future<Object?>'.
}

// Inferred return type of function literal is `Future<void>`, no error.
Future<Object?> Function() test2 = () async {
  return v;
};

void main() {
  test1();
  test2();
}
