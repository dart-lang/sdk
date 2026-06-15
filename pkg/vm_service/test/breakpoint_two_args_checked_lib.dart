// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'common/test_helper.dart';

class NotGeneric {}

void testeeMain() {
  final x = List<dynamic>.filled(1, null);
  final y = 7;
  debugger(); // LINE_A
  print('Statement');
  x[0] = 3; // LINE_B
  x is NotGeneric; // LINE_C
  y & 4; // LINE_D
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testeeMain);
}
