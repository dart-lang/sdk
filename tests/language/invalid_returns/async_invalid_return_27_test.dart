// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/*
* `return exp;` where `exp` has static type `S` is an error if `flatten(S)` is
  `void` and `flatten(T)` is not `void`, `dynamic`, or `Null`.
*/
Future<void> v = null;
//               ^^^^
// [analyzer] STATIC_TYPE_WARNING.INVALID_ASSIGNMENT
// [cfe] A value of type 'Null' can't be assigned to a variable of type 'Future<void>'.
Future<int> test() async {
  return v;
  //     ^
  // [analyzer] STATIC_TYPE_WARNING.RETURN_OF_INVALID_TYPE
  // [cfe] This expression has type 'void' and can't be used.
}

void main() {
  test();
}
