// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:async';
import 'dart:isolate';

import 'async_helper.dart';

void test(void onDone(bool success)) {
  Duration ms = const Duration(milliseconds: 1);
  int expected = 4;

  void timerCallback() {
    if (--expected == 0) onDone(true);
  }

  new Timer(ms * 0, timerCallback);
  new Timer(ms * 10, timerCallback);
  new Timer(ms * 100, timerCallback);
  new Timer(ms * 1000, timerCallback);
}

main() {
  asyncTest(test);
}
