// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'common/test_helper.dart';

extension Foo on String {
  int parseInt(int x) {
    debugger();
    return foo();
  }

  int foo() => 42;
}

void testFunction() {
  print('10'.parseInt(21));
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testFunction);
}
