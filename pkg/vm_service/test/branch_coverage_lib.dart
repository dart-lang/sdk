// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'common/test_helper.dart';

int ifTest(x) {
  if (x > 0) {
    if (x > 10) {
      return 10;
    } else {
      return 1;
    }
  } else {
    return 0;
  }
}

void testFunction() {
  debugger();
  ifTest(1);
  debugger();
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testFunction);
}
