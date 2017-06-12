// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:async';
import 'dart:convert';
import 'unicode_tests.dart';
import "package:async_helper/async_helper.dart";

void runTest(List<int> bytes, expected) {
  var controller = new StreamController();
  asyncStart();
  UTF8.decodeStream(controller.stream).then((decoded) {
    Expect.equals(expected, decoded);
    asyncEnd();
  });
  int i = 0;
  while (i < bytes.length) {
    List nextChunk = [];
    for (int j = 0; j < 3; j++) {
      if (i < bytes.length) {
        nextChunk.add(bytes[i]);
        i++;
      }
    }
    controller.add(nextChunk);
  }
  controller.close();
}

main() {
  for (var test in UNICODE_TESTS) {
    var bytes = test[0];
    var expected = test[1];
    runTest(bytes, expected);
  }
}
