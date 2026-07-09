// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'common/test_helper.dart';

void testFunction() {
  final listOfRecord = [(42, foo: 42.42, bar: 'fortytwo')];
  debugger();
  print(helper(listOfRecord));
}

bool helper(List<(int, {double foo, String bar})> listOfRecord) {
  final record = listOfRecord.first;
  return record.$1 == 42 && record.foo >= 42.0 && record.bar.length >= 4;
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testFunction);
}
