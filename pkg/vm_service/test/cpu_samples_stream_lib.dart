// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'common/test_helper.dart';

int fib(int n) {
  if (n <= 1) {
    return n;
  }
  return fib(n - 1) + fib(n - 2);
}

Future<void> testMain() async {
  int i = 10;
  while (true) {
    ++i;
    // Create progressively deeper stacks to more quickly fill the sample
    // buffer.
    fib(i);
  }
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
