// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'common/test_helper.dart';

void testFunction(bool flag) // LINE_A
{
  if (flag) {
    print('Yes');
  } else {
    print('No');
  }
}

void testMain() {
  debugger();
  testFunction(true);
  testFunction(false);
  print('Done');
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
