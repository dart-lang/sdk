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

Future<int> //# wrongTypeParameter: static type warning
foo3() async {
  return "String";
}

// Future<int, String> is treated like Future<dynamic>
Future<int, String> //# tooManyTypeParameters: static type warning
foo4() async {
  return "String";
}

int //# wrongReturnType: static type warning, dynamic type error
foo5() async {
  return 3;
}

Future<int> foo6() async {
  // This is fine, the future is flattened
  return new Future<int>.value(3);
}

Future<Future<int>> //# nestedFuture: static type warning
foo7() async {
  return new Future<int>.value(3);
}

test() async {
  Expect.equals(3, await foo1());
  Expect.equals(3, await foo2());
  Expect.equals("String", await foo3());
  Expect.equals("String", await foo4());
  Expect.equals(3, await foo5());
  Expect.equals(3, await await foo6());
  Expect.equals(3, await await foo7());
}

main() {
  asyncTest(test);
}
