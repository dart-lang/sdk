// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common/test_helper.dart';

int foo() => 42;

dynamic testeeMain() {
  foo(); // LINE_A

  final dynamic list = [1, 2, 3];
  list.clear(); // LINE_B
  print(list);

  final dynamic local = list; // LINE_C
  return local;
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testeeMain);
}
