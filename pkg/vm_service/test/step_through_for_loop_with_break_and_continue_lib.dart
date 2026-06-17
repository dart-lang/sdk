// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

void code() {
  int count = 0; // LINE_A
  for (int i = 0; i < 42; ++i) {
    if (i == 2) {
      continue;
    }
    if (i == 3) {
      break;
    }
    count++;
  }
  print(count);
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: code);
}
