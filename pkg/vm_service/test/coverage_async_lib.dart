// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'common/test_helper.dart';

Future<int> asyncFunction() async {
  await Future.delayed(const Duration(milliseconds: 1));
  return 123;
}

Stream<int> asyncGenerator() async* {
  await Future.delayed(const Duration(milliseconds: 1));
  yield 456;
}

Iterable<int> syncGenerator() sync* {
  yield 789;
}

Future<void> wrapperFunction() async {
  print(await asyncFunction());
  await for (final value in asyncGenerator()) {
    print(value);
  }
  for (final value in syncGenerator()) {
    print(value);
  }
}

Future<void> testFunction() async {
  debugger();
  await wrapperFunction();
  debugger();
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testFunction);
}
