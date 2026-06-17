// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'common/test_helper.dart';

/* LINE_A */ Future<String> testFunction() async {
  await Future.delayed(Duration(milliseconds: 1));
  return 'Done';
}

Future<void> testMain() async {
  debugger();
  print(await testFunction());
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
