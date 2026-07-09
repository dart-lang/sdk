// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: dead_code

import 'common/test_helper.dart';

void testMain() {
  final bool foo = false;
  if (foo) {} // LINE_A

  const bar = false;
  if (bar) {} // LINE_B

  while (foo) {} // LINE_C

  while (bar) {} // LINE_D
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
