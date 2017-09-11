// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'dart:async';

StackTrace captureStackTrace() {
  try {
    throw 0;
  } catch (e, st) {
    return st;
  }
}

main() {
  StackTrace trace = captureStackTrace();
  var controller;
  controller = new StreamController(onListen: () {
    controller.addError("error", trace);
    controller.close();
  });
  asyncStart();
  controller.stream.handleError((e, st) {
    Expect.equals("error", e);
    Expect.identical(trace, st);
  }).listen((x) {
    throw "should never be reached";
  }, onDone: asyncEnd);
}
