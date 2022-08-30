// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import 'dart:async';
import 'event_helper.dart';

void main() {
  testSyncAddStream(StreamController<int>());
  testSyncAddStream(StreamController<int>(sync: true));
  testSyncAddStream(StreamController<int>.broadcast());
  testSyncAddStream(StreamController<int>.broadcast(sync: true));
  testMultiSyncAddStream();
}

void testSyncAddStream(StreamController<int> controller) {
  var source = StreamController<int>(sync: true);
  var value = -1;
  controller.stream.listen((v) {
    value = v;
  }, onError: (e, s) {
    value = 117;
  });
  controller.addStream(source.stream);
  source.add(42);
  Expect.equals(42, value);
  source.addError("err");
  Expect.equals(117, value);
}

void testMultiSyncAddStream() {
  var source = StreamController<int>(sync: true);
  var value = -1;
  var stream = Stream<int>.multi((controller) {
    controller.addStream(source.stream);
  });
  stream.listen((v) {
    value = v;
  }, onError: (e, s) {
    value = 117;
  });
  source.add(42);
  Expect.equals(42, value);
  source.addError("err");
  Expect.equals(117, value);
}
