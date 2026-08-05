// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

class Foo {}

Never doThrow() {
  throw 'TheException';
}

Future<Never> asyncThrower() async {
  // ignore: await_only_futures
  await 0; // force async gap
  doThrow();
}

Future<void> testeeMain() async {
  // Trigger optimization via OSR.
  int s = 0;
  for (int i = 0; i < 100; i++) {
    s += i;
  }
  print(s);
  // No try ... catch.
  await asyncThrower(); // LINE_A
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testeeMain);
}
