// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';

import 'async_helper.dart';

void test(void onDone(bool success)) {
  int expected = 4;

  void timerCallback(timer) {
    if (--expected == 0) onDone(true);
  }

  new Timer(0, timerCallback);
  new Timer(10, timerCallback);
  new Timer(100, timerCallback);
  new Timer(1000, timerCallback);
}

main() {
  asyncTest(test);
}
