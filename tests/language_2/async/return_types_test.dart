// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

Future foo1() async {
  return 3;
}

Future<int> foo2() async {
  return 3;
}

Future<int>
foo3() async {
  return "String";
  //     ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.RETURN_OF_INVALID_TYPE
  // [cfe] A value of type 'Future<String>' can't be assigned to a variable of type 'FutureOr<int>'.
}

Future<int, String>
// [error line 25, column 1, length 19]
// [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_TYPE_ARGUMENTS
// [cfe] Expected 1 type arguments.
foo4() async {
  return "String";
}

int
// [error line 33, column 1, length 3]
// [analyzer] COMPILE_TIME_ERROR.ILLEGAL_ASYNC_RETURN_TYPE
foo5() async {
// [error line 36, column 1]
// [cfe] Functions marked 'async' must have a return type assignable to 'Future'.
  return 3;
}

Future<int> foo6() async {
  // This is fine, the future is flattened
  return new Future<int>.value(3);
}

Future<Future<int>>
foo7() async {
  return new Future<int>.value(3);
  //     ^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.RETURN_OF_INVALID_TYPE
}

Iterable<int> foo8() sync* {
  yield 1;
  // Can only have valueless return in sync* functions.
  return 8;
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.RETURN_IN_GENERATOR
// [cfe] 'sync*' and 'async*' can't return a value.
//^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.RETURN_IN_GENERATOR
}

Stream<int> foo9() async* {
  yield 1;
  // Can only have valueless return in async* functions.
  return 8;
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.RETURN_IN_GENERATOR
// [cfe] 'sync*' and 'async*' can't return a value.
//^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.RETURN_IN_GENERATOR
}

test() async {
  Expect.equals(3, await foo1());
  Expect.equals(3, await foo2());
  Expect.equals("String", await foo3());
  Expect.equals("String", await foo4());
  Expect.equals(3, await foo5());
  Expect.equals(3, await await foo6());
  Expect.equals(3, await await foo7());
  Expect.listEquals([1], foo8().toList());
  Expect.listEquals([1], await foo9().toList());
}

main() {
  asyncTest(test);
}
