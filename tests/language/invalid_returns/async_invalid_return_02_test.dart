// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

/* `return;` is an error if the future value type of the function is not
 * `void`, `dynamic`, or `Null`.
 */

FutureOr<int> test1() async {
  return;
//^
// [analyzer] unspecified
// [cfe] A value must be explicitly returned from a non-void async function.
}

FutureOr<int> Function() test2 = () async {
  return;
//^
// [analyzer] unspecified
// [cfe] A value must be explicitly returned from a non-void async function.
};

void main() {
  test1();
  test2();
}
