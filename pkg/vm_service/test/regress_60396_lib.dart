// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

void testeeMain() {
  (() {
    (() {
      return 1 + 2; // LINE_A
    })();
  })();
}

// We define this enum because the bug that this test is a regression test
// against was that Debugger::FindBestFit would sometimes attempt to resolve
// breakpoints in functions with non-real token positions like [_enumToString].
enum MyEnum { A, B }

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testeeMain);
}
