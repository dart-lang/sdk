// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'common/test_helper.dart';

class Bar {
  static const String field = 'field'; // LINE_A
}

Future<String> fooAsync(int x) async {
  if (x == 42) {
    return '*' * x;
  }
  return List.generate(x, (_) => 'xyzzy').join(' ');
} // LINE_B

Future<void> testFunction() async {
  await Future.delayed(Duration(milliseconds: 500));
  await fooAsync(42);
  debugger();
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testFunction);
}
