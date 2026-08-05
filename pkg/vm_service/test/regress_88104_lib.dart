// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';

import 'common/test_helper.dart';

class Foo<T> {}

Future<void> testMain() async {
  debugger(); // LINE_A
  for (int i = 0; i < 10; ++i) {
    Foo<int>();
    await Future.delayed(const Duration(milliseconds: 10));
  }
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
