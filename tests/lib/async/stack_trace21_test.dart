// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';
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
  controller = new StreamController(
    onListen: () {
      controller.addError("error", trace);
      controller.close();
    },
  );
  asyncStart();
  controller.stream.listen(
    (_) {
      throw "should never be reached";
    },
    onError: (e, st) {
      Expect.equals("error", e);
      Expect.identical(trace, st);
    },
    onDone: () {
      asyncEnd();
    },
  );
}
