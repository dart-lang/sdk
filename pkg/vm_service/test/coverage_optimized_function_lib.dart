// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'common/test_helper.dart';

String optimizedFunction() {
  return 5.toString() + 3.toString();
}

void testFunction() {
  for (var i = 0; i < 20; i++) {
    optimizedFunction();
  }
  debugger();
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testFunction);
}
