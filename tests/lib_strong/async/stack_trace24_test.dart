// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'dart:async';

main() {
  var controller;
  controller = new StreamController(onListen: () {
    controller.add(499);
    controller.close();
  });
  asyncStart();
  controller.stream.map((e) {
    throw "error";
  }).listen((_) {
    throw "should never be reached";
  }, onError: (e, st) {
    Expect.equals("error", e);
    Expect.isNotNull(st);
  }, onDone: () {
    asyncEnd();
  });
}
