// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'common/test_helper.dart';

int counter = 0;

void periodicTask(_) // LINE_C
{
  counter++;
  counter++; // Line 19.  We set our breakpoint here. // LINE_A
  counter++; // LINE_B
  if (counter % 300 == 0) {
    print('counter = $counter');
  }
}

void startTimer() {
  Timer.periodic(const Duration(milliseconds: 10), periodicTask);
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: startTimer);
}
