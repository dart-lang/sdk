// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

void testMain() {
  final (int, String name, bool) triple = (3, 'f', true); // LINE_A
  final ({int n, String s}) pair = (n: 2, s: 's'); // LINE_B
  final (bool, num, {int n, String s}) quad = // LINE_C
      (false, 3.14, n: 7, s: 'd');
  print('$pair $triple $quad'); // LINE_D
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
