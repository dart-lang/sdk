// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

void code() // LINE_A
{
  for (int datapoint in generator()) {
    print(datapoint);
  }
}

Iterable<dynamic> generator() sync* {
  final int x = 3;
  final int y = 4;
  yield y;
  final int z = x + y;
  yield z;
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: code);
}
