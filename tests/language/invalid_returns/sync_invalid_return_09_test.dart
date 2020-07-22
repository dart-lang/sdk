// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/* `return exp;` where `exp` has static type `S` is an error if `T` is `void`
 * and `S` is not `void`, `dynamic`, or `Null`.
 */

FutureOr<int> v = 0;
void test() {
  return v;
  //     ^
  // [analyzer] unspecified
  // [cfe] Can't return a value from a void function.
}

void main() {
  test();
}
