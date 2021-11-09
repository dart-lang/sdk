// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/47610.
// Tests returning value from a deep context depth along with
// breaking from 'await for'.

import "dart:async";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

Stream<int> foo() async* {
  for (int i = 0; i < 2; ++i) {
    for (int j = 0; j < 2; ++j) {
      for (int k = 0; k < 2; ++k) {
        yield i + j + k;
      }
    }
  }
}

void test() async {
  await for (var x in foo()) {
    Expect.equals(0, x);
    break;
  }
}

void main() {
  asyncTest(test);
}
