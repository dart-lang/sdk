// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

Future<String> asyncString() async {
  return "foo";
}

Future<String> asyncString2() async {
  return asyncString();
}

Iterable<String> syncStarString() sync* {
  yield "foo";
  yield* syncStarString2();
  yield* stringList;
}

Iterable<String> syncStarString2() sync* {
  yield "foo";
}

Stream<String> asyncStarString() async* {
  yield "foo";
  yield* asyncStarString2();
  yield await asyncString();
}

Stream<String> asyncStarString2() async* {
  yield "bar";
}

List<String> stringList = ["bar"];

main() async {
  String str = await asyncString();
}
