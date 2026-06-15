// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'common/test_helper.dart';

// Issue: https://github.com/dart-lang/sdk/issues/36622
Future<void> testMain() async {
  for (int i = 0; i < 2; i++) {
    if (i > 0) {
      break; // LINE_A
    }
    await Future.delayed(Duration(seconds: 1));
  }
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
