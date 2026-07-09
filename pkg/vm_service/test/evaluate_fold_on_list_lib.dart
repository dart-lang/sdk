// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'common/test_helper.dart';

void testFunction() {
  final List<String> x = ['a', 'b', 'c'];
  final int xCombinedLength = x.fold<int>(
    0,
    (previousValue, element) => previousValue + element.length,
  );
  debugger();
  print('xCombinedLength = $xCombinedLength');
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testFunction);
}
