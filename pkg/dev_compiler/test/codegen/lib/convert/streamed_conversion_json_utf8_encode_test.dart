// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:async';
import 'dart:convert';
import 'json_unicode_tests.dart';
import "package:async_helper/async_helper.dart";

final JSON_UTF8 = JSON.fuse(UTF8);


Stream<List<int>> encode(Object o) {
  var controller;
  controller = new StreamController(onListen: () {
    controller.add(o);
    controller.close();
  });
  return controller.stream.transform(JSON_UTF8.encoder);
}

void testUnpaused(List<int> expected, Stream stream) {
  asyncStart();
  stream.toList().then((list) {
    var combined = [];
    list.forEach(combined.addAll);
    Expect.listEquals(expected, combined);
    asyncEnd();
  });
}

void testWithPauses(List<int> expected, Stream stream) {
  asyncStart();
  var accumulated = [];
  var sub;
  sub = stream.listen((x) {
    accumulated.addAll(x);
    sub.pause(new Future.delayed(Duration.ZERO));
  }, onDone: () {
    Expect.listEquals(expected, accumulated);
    asyncEnd();
  });
}

void main() {
  for (var test in JSON_UNICODE_TESTS) {
    var expected = test[0];
    var object = test[1];
    testUnpaused(expected, encode(object));
    testWithPauses(expected, encode(object));
  }
}
