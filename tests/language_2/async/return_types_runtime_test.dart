// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

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


foo3() async {
  return "String";
}


foo4() async {
  return "String";
}


foo5() async {
  return 3;
}

Future<int> foo6() async {
  // This is fine, the future is flattened
  return new Future<int>.value(3);
}


foo7() async {
  return new Future<int>.value(3);
}

Iterable<int> foo8() sync* {
  yield 1;
  // Can only have valueless return in sync* functions.
  return

      ;
}

Stream<int> foo9() async* {
  yield 1;
  // Can only have valueless return in async* functions.
  return

      ;
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
