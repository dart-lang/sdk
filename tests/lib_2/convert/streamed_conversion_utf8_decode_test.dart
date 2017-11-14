// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:async';
import 'dart:convert';
import 'unicode_tests.dart';
import "package:async_helper/async_helper.dart";

Stream<String> decode(List<int> bytes, int chunkSize) {
  var controller;
  controller = new StreamController<List<int>>(onListen: () {
    int i = 0;
    while (i < bytes.length) {
      List nextChunk = <int>[];
      for (int j = 0; j < chunkSize; j++) {
        if (i < bytes.length) {
          nextChunk.add(bytes[i]);
          i++;
        }
      }
      controller.add(nextChunk);
    }
    controller.close();
  });
  return controller.stream.transform(UTF8.decoder);
}

testUnpaused(String expected, Stream stream) {
  asyncStart();
  stream.toList().then((list) {
    StringBuffer buffer = new StringBuffer();
    buffer.writeAll(list);
    Expect.stringEquals(expected, buffer.toString());
    asyncEnd();
  });
}

testWithPauses(String expected, Stream stream) {
  asyncStart();
  StringBuffer buffer = new StringBuffer();
  var sub;
  sub = stream.listen((x) {
    buffer.write(x);
    sub.pause(new Future.delayed(Duration.ZERO));
  }, onDone: () {
    Expect.stringEquals(expected, buffer.toString());
    asyncEnd();
  });
}

main() {
  for (var test in UNICODE_TESTS) {
    var bytes = test[0];
    var expected = test[1];
    testUnpaused(expected, decode(bytes, 1));
    testWithPauses(expected, decode(bytes, 1));
    testUnpaused(expected, decode(bytes, 2));
    testWithPauses(expected, decode(bytes, 2));
    testUnpaused(expected, decode(bytes, 3));
    testWithPauses(expected, decode(bytes, 3));
    testUnpaused(expected, decode(bytes, 4));
    testWithPauses(expected, decode(bytes, 4));
  }
}
