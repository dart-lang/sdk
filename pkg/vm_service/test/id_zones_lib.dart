// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'common/test_helper.dart';

class D {}

@pragma('vm:entry-point')
D getDLiteral() => D();

class C {
  final field = D();
}

void testeeMain() {
  // ignore: unused_local_variable
  final c = C();
  debugger(); // LINE_A
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testeeMain);
}
