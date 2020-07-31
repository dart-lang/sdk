// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for issue: https://github.com/dart-lang/sdk/issues/39994

import "dart:async";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

Stream<String> testStream() async* {
  try {
    await testThrow();
    yield "A";
  } catch (e) {
    yield "B";
    yield "C";
    yield "D";
  }
}

testThrow() async {
  throw Exception();
}

test() async {
  var result = await testStream().toList();
  Expect.listEquals(["B", "C", "D"], result);
}

main() {
  asyncTest(test);
}
