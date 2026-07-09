// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library async_start_test;

import "dart:async";

import "package:expect/expect.dart";

void main() async {
  var results = [];

  f() async* {
    yield 0;
    yield 1;
    yield 2;
  }

  //Broken, the value 1 was lost.
  await for (var i in f()) {
    results.add(i);
    if (i == 0) {
      // This should pause the stream subscription.
      await Future.delayed(Duration(milliseconds: 500));
    }
  }

  Expect.listEquals([0, 1, 2], results);
}
