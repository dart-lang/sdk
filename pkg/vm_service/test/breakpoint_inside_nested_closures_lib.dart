// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

int f() {
  return (() {
    (() {
      return 1 + 2;
    })();
    return (() {
      return 3 + 4; // LINE_A
    })();
  })();
}

void testeeMain() {
  f();
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testeeMain);
}
