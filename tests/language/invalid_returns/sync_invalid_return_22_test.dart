// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/* `return exp;` where `exp` has static type `S` is an error if `S` is not
 * assignable to `T`.
 */

Future<int> v = Future.value(0);
Future<String> test() {
  return v;
  //     ^
  // [analyzer] unspecified
  // [cfe] A value of type 'Future<int>' can't be returned from a function with return type 'Future<String>'.
}

void main() {
  test();
}
