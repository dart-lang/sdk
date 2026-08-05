// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'common/test_helper.dart';

int value = 0;

int incValue(int amount) {
  value += amount;
  return amount;
}

Future<void> testMain() async {
  incValue(incValue(1)); // LINE_A
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
