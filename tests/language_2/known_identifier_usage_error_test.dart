// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The identifiers listed below are mentioned in the grammar, but none of
// them is a reserved word or a built-in identifier. Such an identifier can
// be used just like all other identifiers, with the exceptions mentioned
// below. Here are said 'known' identifiers:
//
//   `async`, `await`, `hide`, `of`, `on`, `show`, `sync`, `yield`
//
// The following exceptions apply:
//
//   It is a compile-time error to use `async`, `await`, or `yield` as an
//   identifier in the body of a function marked `async`, `async*`, or
//   `sync*`.
//
//   It is a compile-time error if an asynchronous for-in appears inside a
//   synchronous function.

import 'dart:async';

Future<int> f1() async {
  int async = 1; //# 01: syntax error
  int await = 1; //# 02: syntax error
  int yield = 1; //# 03: syntax error

  Stream<int> s = new Stream<int>.fromFuture(new Future<int>.value(1));
  await for (int i in s) {
    return i + 1;
  }
}

Stream<int> f2() async* {
  int async = 1; //# 04: syntax error
  int await = 1; //# 05: syntax error
  int yield = 1; //# 06: syntax error

  Stream<int> s = new Stream<int>.fromFuture(new Future<int>.value(1));
  await for (var i in s) {
    yield i + 1;
  }
}

Iterable<int> f3() sync* {
  int async = 1; //# 07: syntax error
  int await = 1; //# 08: syntax error
  int yield = 1; //# 09: syntax error

  Stream<int> s = new Stream<int>.fromFuture(new Future<int>.value(1));
  await for (int i in s) { //# 10: compile-time error
    yield i + 1; //# 10: continued
  } //# 10: continued
}

int f4() {
  int async = 1;
  int await = 1;
  int yield = 1;

  Stream s = new Stream<int>.fromFuture(new Future<int>.value(1));
  await for (int i in s) { //# 11: compile-time error
    return i + 1; //# 11: continued
  } //# 11: continued

}

main() {
  Future<int> f = f1();
  Stream s = f2();
  Iterable<int> i = f3();
  int x = f4();
}
