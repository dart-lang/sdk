// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

void code() // LINE_A
{
  switch (switchOnMe.length) {
    case 0:
      print('(got 0!');
      continue label;
    label:
    case 1:
      print('Got 0 or 1!');
      break;
    case 2:
      print('Got 2!');
      break;
    default:
      print('Got lost!');
  }
}

final switchOnMe = <String>[];

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: code);
}
