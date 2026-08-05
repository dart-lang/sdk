// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

void testMain() {
  final funcs = {
    'a': () // LINE_A
        {
      print('a');
    },
    'b': () // LINE_B
        {
      print('b');
    },
  };

  funcs['a']!();
  funcs['b']!();
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
