// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'common/test_helper.dart';

Future<Never> helper() async {
  print('helper'); // LINE_A
  throw 'a'; // LINE_B
}

Future<void> testMain() async {
  debugger(); // LINE_0
  print('mmmmm'); // LINE_C
  try {
    await helper(); // LINE_D
  } catch (e) {
    // arrive here on error.
    print('error: $e'); // LINE_E
  } finally {
    // arrive here in both cases.
    print('foo'); // LINE_F
  }
  print('z'); // LINE_G
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
