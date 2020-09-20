// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/* `return exp;` where `exp` has static type `S` is an error if `S` is `void`
 * and `T` is not `void` or `dynamic`.
 */

void v = null;
Future<int>? test() {
  return v;
  //     ^
  // [analyzer] unspecified
  // [cfe] A value of type 'void' can't be returned from a function with return type 'Future<int>?'.
}

void main() {
  test();
}
