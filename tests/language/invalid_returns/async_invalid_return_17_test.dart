// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/* `return exp;` where `exp` has static type `S` is an error if the future
 * value type of the function is `void` and `flatten(S)` is not
 * `void`, `dynamic`, `Null`, `void*`, `dynamic*`, or `Null*`.
 */

Future<Object> v = Future.value(Object());

void test1() async {
  return v;
  //     ^
  // [analyzer] unspecified
  // [cfe] A value of type 'Future<Object>' can't be returned from an async function with return type 'void'.
}

// Inferred return type of function literal is `Future<void>`.
void Function() test2 = () async {
  return v;
  //     ^
  // [analyzer] unspecified
  // [cfe] A value of type 'Future<Object>' can't be returned from an async function with return type 'Future<void>'.
};

void main() {
  test1();
  test2();
}
