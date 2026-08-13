// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'common/test_helper.dart';

Future<String> testFunction(String caption) async {
  await Future.delayed(Duration(milliseconds: 1)); // LINE_A
  return caption; // LINE_B
}

Future<void> testMain() async {
  debugger();
  final str = await testFunction('The caption');
  print(str);
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
