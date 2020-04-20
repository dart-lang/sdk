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
  Completer completer = new Completer();
  StackTrace trace = captureStackTrace();
  asyncStart();
  completer.future.whenComplete(() => 499).then<Null>((_) {
    throw "should never be reached";
  }).then<Null>((_) {
    throw "Unreachable";
  }, onError: (e, st) {
    Expect.equals("c-error", e);
    Expect.identical(trace, st);
    asyncEnd();
  });
  completer.completeError("c-error", trace);
}
