// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/* `return;` is an error if the future value type of the function is not
 * `void`, `dynamic`, or `Null`.
 */

Future<Object?> test1() async {
  return;
  // [error column 3, length 6]
  // [analyzer] COMPILE_TIME_ERROR.RETURN_WITHOUT_VALUE
  // [cfe] A value must be explicitly returned from a non-void async function.
}

// Inferred return type of function literal is `Future<Null>`, no error.
Future<Object?> Function() test2 = () async {
  return;
};

void main() {
  test1();
  test2();
}
