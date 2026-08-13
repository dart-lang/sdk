// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

void code() {
  code2('a'); // LINE_A
  code2('b');
  code2('c');
  code2('d');
}

void code2(String key) {
  switch (key) {
    case 'a':
      print('a!');
      break;
    case 'b':
    case 'c':
      print('b or c!');
      break;
    default:
      print('neither a, b or c...');
  }
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: code);
}
