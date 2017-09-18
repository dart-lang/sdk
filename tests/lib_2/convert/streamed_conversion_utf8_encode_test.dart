// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:async';
import 'dart:convert';
import 'unicode_tests.dart';
import "package:async_helper/async_helper.dart";

Stream<List<int>> encode(String string, int chunkSize) {
  var controller;
  controller = new StreamController<String>(onListen: () {
    int i = 0;
    while (i < string.length) {
      if (i + chunkSize <= string.length) {
        controller.add(string.substring(i, i + chunkSize));
      } else {
        controller.add(string.substring(i));
      }
      i += chunkSize;
    }
    controller.close();
  });
  return controller.stream.transform(UTF8.encoder);
}

void testUnpaused(List<int> expected, Stream stream) {
  asyncStart();
  stream.toList().then((list) {
    var combined = [];
    // Flatten the list.
    list.forEach(combined.addAll);
    Expect.listEquals(expected, combined);
    asyncEnd();
  });
}

void testWithPauses(List<int> expected, Stream stream) {
  asyncStart();
  var combined = <int>[];
  var sub;
  sub = stream.listen((x) {
    combined.addAll(x);
    sub.pause(new Future.delayed(Duration.ZERO));
  }, onDone: () {
    Expect.listEquals(expected, combined);
    asyncEnd();
  });
}

main() {
  for (var test in UNICODE_TESTS) {
    var expected = test[0];
    var string = test[1];
    testUnpaused(expected, encode(string, 1));
    testWithPauses(expected, encode(string, 1));
    testUnpaused(expected, encode(string, 2));
    testWithPauses(expected, encode(string, 2));
  }
}
