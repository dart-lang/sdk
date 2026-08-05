// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'common/test_helper.dart';

Future<void> code() async {
  // ignore: unused_local_variable
  int count = 0; // LINE_A
  await for (var num in naturalsTo(2)) {
    print(num);
    count++;
  }
}

Stream<int> naturalsTo(int n) async* {
  int k = 0;
  while (k < n) {
    k++;
    yield k;
  }
  yield 42;
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: code);
}
