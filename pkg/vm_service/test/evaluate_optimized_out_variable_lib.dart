// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

bool debug = false;

bool bar(int i) {
  if (i == 2) {
    if (debug) {
      print('woke up'); // LINE_A
    }
    return true;
  }
  return false;
}

void foo() {
  final List<int> data = [1, 2, 3];
  for (int i in data) {
    if (bar(i)) {
      break;
    }
  }
}

void testeeMain() {
  // Trigger optimization of [foo].
  for (int i = 0; i < 20; i++) {
    foo();
  }
  debug = true;
  foo();
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testeeMain);
}
