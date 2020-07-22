// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/* `return;` is an error if the future value type of the function is not
 * `void`, `dynamic`, or `Null`.
 */

Object test1() async {
  return;
//^
// [analyzer] unspecified
// [cfe] A value must be explicitly returned from a non-void async function.
}

Object? test2() async {
  return;
//^
// [analyzer] unspecified
// [cfe] A value must be explicitly returned from a non-void async function.
}

// Inferred return type of function literal is `Future<Null>`, no error.
Object Function() test3 = () async {
  return;
};

// Inferred return type of function literal is `Future<Null>`, no error.
Object? Function() test4 = () async {
  return;
};

void main() {
  test1();
  test2();
  test3();
  test4();
}
