// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';

import 'common/test_helper.dart';

int counter = 0;

// This name is used in a test below.
void msgHandler(_) {}

void periodicTask(_) {
  debugger(message: 'fo', when: true); // LINE_A
  counter++;
  if (counter % 300 == 0) {
    print('counter = $counter');
  }
}

void startTimer() {
  Timer.periodic(const Duration(milliseconds: 10), periodicTask);
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeBefore: startTimer);
}
