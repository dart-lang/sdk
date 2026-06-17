// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'common/test_helper.dart';

Future<void> testMain() async {
  await func1();
}

Future func1() async => await func2();
Future func2() async => await func3();
Future func3() async => await func4();
Future func4() async => await func5();
Future func5() async => await func6();
Future func6() async => await func7();
Future func7() async => await func8();
Future func8() async => await func9();
Future func9() async => await func10();
Future func10() async {
  debugger(); // LINE_0
  // ignore: await_only_futures
  await 0; // LINE_A
  debugger(); // LINE_1
  print('Hello, world!'); // LINE_B
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
