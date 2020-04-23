// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:expect/expect.dart';

get await => 4;

// For functions that are declared with the async modifier we treat await as
// keyword.

test0() async {
  var x = await 7;
  Expect.equals(7, x);
  var await = 1;
  //  ^^^^^
  // [analyzer] SYNTACTIC_ERROR.ASYNC_KEYWORD_USED_AS_IDENTIFIER
  // [cfe] 'await' can't be used as an identifier in 'async', 'async*', or 'sync*' methods.
}

test1() async {
  var x = await 9;
  Expect.equals(9, x);
  var y = await;
  //           ^
  // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
  // [cfe] Expected an identifier, but got ';'.
}

// For functions that are not declared with the async modifier we allow await to
// be used as an identifier.

test2() {
  var y = await;
  Expect.equals(4, y);
  var x = await 1;
  //      ^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ';' after this.
}

test3() {
  var await = 3;
  Expect.equals(3, await);
  var x = await 1;
  //      ^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  // [cfe] Expected ';' after this.
}

main() {
  test0();
  test1();
  test2();
  test3();
}
