// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'common/test_helper.dart';

void method(int value, _) {
  debugger();
}

void testeeMain() {
  int i = 0;
  while (true) {
    if (++i % 100000000 == 0) {
      method(10000, 50);
    }
  }
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testeeMain);
}
